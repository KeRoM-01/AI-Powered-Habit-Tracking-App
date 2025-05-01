// ignore_for_file: unnecessary_to_list_in_spreads, library_private_types_in_public_api, use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_habit_tracking_app/services/firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai_habit_tracking_app/notification/notifcation_service.dart';
import 'package:ai_habit_tracking_app/services/habit_recommender.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String _userName = '';
  String _recommendedHabit = '';
  final NotificationService _notificationService = NotificationService();
  final HabitRecommender _habitRecommender = HabitRecommender();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeNotifications();
    _loadRecommendation();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
    await _scheduleAllHabitNotifications();
  }

  Future<void> _loadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('User ID: ${user.uid}');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userName = userDoc['name'] ?? 'User';
        });
      }
    }
  }

  Future<void> _loadRecommendation() async {
    try {
      try {
        String assetList = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
        print('AssetManifest.json contains: ${assetList.contains('habit_recommender.tflite')}');
      } catch (e) {
        print('Error checking AssetManifest.json: $e');
      }

      String recommendation = await _habitRecommender.recommendHabit(
          FirebaseAuth.instance.currentUser!.uid);
      print('Recommendation: $recommendation');
      if (mounted) {
        setState(() {
          _recommendedHabit = recommendation == 'No habits found'
              ? 'Add habits to get recommendations'
              : recommendation;
        });
      }
    } catch (e) {
      print('Error loading recommendation: $e');
      if (mounted) {
        setState(() {
          _recommendedHabit = 'Failed to load recommendation: ${e.toString().split('\n')[0]}';
        });
      }
    }
  }

  Future<void> _scheduleAllHabitNotifications() async {
    final snapshot = await FirestoreService().getHabits().first;
    if (snapshot.docs.isEmpty) return;

    final habits = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    for (var habit in habits) {
      final habitId = habit['id'];
      final habitName = habit['habit'];
      final morningReminder = habit['morningReminder'] ?? false;
      final eveningReminder = habit['eveningReminder'] ?? false;
      final nightReminder = habit['nightReminder'] ?? false;
      final morningCompleted = habit['morningCompleted'] ?? false;
      final eveningCompleted = habit['eveningCompleted'] ?? false;
      final nightCompleted = habit['nightCompleted'] ?? false;

      final now = DateTime.now();
      final morningTime = DateTime(now.year, now.month, now.day, 8, 0);
      final eveningTime = DateTime(now.year, now.month, now.day, 18, 0);
      final nightTime = DateTime(now.year, now.month, now.day, 22, 0);

      if (morningReminder) {
        await _notificationService.scheduleHabitNotification(
          habitId: habitId,
          habitName: habitName,
          period: 'morning',
          time: morningTime,
          isCompleted: morningCompleted,
        );
      }
      if (eveningReminder) {
        await _notificationService.scheduleHabitNotification(
          habitId: habitId,
          habitName: habitName,
          period: 'evening',
          time: eveningTime,
          isCompleted: eveningCompleted,
        );
      }
      if (nightReminder) {
        await _notificationService.scheduleHabitNotification(
          habitId: habitId,
          habitName: habitName,
          period: 'night',
          time: nightTime,
          isCompleted: nightCompleted,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome $_userName',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DatePicker(
                        DateTime.now(),
                        initialSelectedDate: DateTime.now(),
                        selectionColor: Colors.deepPurple,
                        selectedTextColor: Colors.white,
                        dateTextStyle: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.bold),
                        dayTextStyle: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 10),
                        monthTextStyle: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 10),
                        onDateChange: (date) {},
                      ),
                    ],
                  ),
                ),
                if (_recommendedHabit.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _recommendedHabit,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                          onPressed: _loadRecommendation,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService().getHabits(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            Image(
                              image: const AssetImage('assets/notask.jpg'),
                              width: 250,
                              height: 250,
                            ),
                            Text(
                              'No habits found. Try adding yours from the + Add habit page.',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }

                    var habits = snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return data;
                    }).toList();

                    var morningHabits = habits
                        .where((habit) => habit['morningReminder'] == true)
                        .toList();
                    var eveningHabits = habits
                        .where((habit) => habit['eveningReminder'] == true)
                        .toList();
                    var nightHabits = habits
                        .where((habit) => habit['nightReminder'] == true)
                        .toList();

                    return Column(
                      children: [
                        if (morningHabits.isNotEmpty) ...[
                          Text(
                            'Morning',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...morningHabits
                              .map((habit) => HabitCard(
                                    habit: habit,
                                    period: 'morning',
                                    userName: _userName,
                                    onCompletionChanged:
                                        _scheduleAllHabitNotifications,
                                  ))
                              .toList(),
                        ],
                        if (eveningHabits.isNotEmpty) ...[
                          Text(
                            'Evening',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...eveningHabits
                              .map((habit) => HabitCard(
                                    habit: habit,
                                    period: 'evening',
                                    userName: _userName,
                                    onCompletionChanged:
                                        _scheduleAllHabitNotifications,
                                  ))
                              .toList(),
                        ],
                        if (nightHabits.isNotEmpty) ...[
                          Text(
                            'Night',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...nightHabits
                              .map((habit) => HabitCard(
                                    habit: habit,
                                    period: 'night',
                                    userName: _userName,
                                    onCompletionChanged:
                                        _scheduleAllHabitNotifications,
                                  ))
                              .toList(),
                        ],
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HabitCard extends StatefulWidget {
  final Map<String, dynamic> habit;
  final String period;
  final String userName;
  final VoidCallback onCompletionChanged;

  const HabitCard({
    super.key,
    required this.habit,
    required this.period,
    required this.userName,
    required this.onCompletionChanged,
  });

  @override
  _HabitCardState createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  bool _isCompleted = false;
  bool _isExpanded = false;
  bool _isDialogShowing = false;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.habit['${widget.period}Completed'] ?? false;

    final lastChecked = widget.habit['lastCheckedDate'] is Timestamp
        ? widget.habit['lastCheckedDate'].toDate()
        : DateTime.now();
    if (lastChecked.day != DateTime.now().day) {
      _firestoreService.updateReminderCompletion(
        widget.habit['id'],
        widget.period,
        false,
      );
      setState(() {
        _isCompleted = false;
      });
    }
  }

  void _showDayFeedbackDialog() async {
    if (_isDialogShowing) return;
    setState(() {
      _isDialogShowing = true;
    });

    await showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(
            'How was your day?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoDialogAction(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('😊', style: TextStyle(fontSize: 25)),
                      const SizedBox(height: 5),
                      Text('Great', style: GoogleFonts.poppins(fontSize: 12)),
                    ],
                  ),
                  onPressed: () async {
                    try {
                      await _firestoreService.addDayFeedback(
                          DateTime.now(), 'Great', '😊');
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your feedback! 🌟',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.deepPurple,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving feedback: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    setState(() {
                      _isDialogShowing = false;
                    });
                  },
                ),
                CupertinoDialogAction(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('😐', style: TextStyle(fontSize: 25)),
                      const SizedBox(height: 5),
                      Text('Okay', style: GoogleFonts.poppins(fontSize: 12)),
                    ],
                  ),
                  onPressed: () async {
                    try {
                      await _firestoreService.addDayFeedback(
                          DateTime.now(), 'Okay', '😐');
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your feedback! 🌟',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.deepPurple,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving feedback: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    setState(() {
                      _isDialogShowing = false;
                    });
                  },
                ),
                CupertinoDialogAction(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('😔', style: TextStyle(fontSize: 25)),
                      const SizedBox(height: 5),
                      Text('Not Good',
                          style: GoogleFonts.poppins(fontSize: 12)),
                    ],
                  ),
                  onPressed: () async {
                    try {
                      await _firestoreService.addDayFeedback(
                          DateTime.now(), 'Not Good', '😔');
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your feedback! 🌟',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.deepPurple,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving feedback: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    setState(() {
                      _isDialogShowing = false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _isDialogShowing = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

void _toggleCompletion() async {
  final newStatus = !_isCompleted;
  final today = DateTime.now();

  if (mounted) {
    setState(() {
      _isCompleted = newStatus;
    });
  }

  await _firestoreService.updateReminderCompletion(
    widget.habit['id'],
    widget.period,
    newStatus,
  );

  final notificationId = _notificationService.generateNotificationId(widget.habit['id'], widget.period);
  if (newStatus) {
    try {
      await _notificationService.showInstantNotification(
        id: notificationId,
        title: 'Habit Completed!',
        body: 'Good job, ${widget.userName}!',
      );
      await _notificationService.cancelHabitNotification(
        habitId: widget.habit['id'],
        period: widget.period,
      );
    } catch (e) {
      print('Error showing completion notification: $e');
    }
  } else {
    try {
      await _notificationService.showInstantNotification(
        id: notificationId,
        title: 'Habit Reminder',
        body: 'You forgot your goal, ${widget.userName}!',
      );
      final now = DateTime.now();
      var scheduledTime = widget.period == 'morning'
          ? DateTime(now.year, now.month, now.day, 8, 0)
          : widget.period == 'evening'
              ? DateTime(now.year, now.month, now.day, 18, 0)
              : DateTime(now.year, now.month, now.day, 22, 0);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      await _notificationService.scheduleHabitNotification(
        habitId: widget.habit['id'],
        habitName: widget.habit['habit'],
        period: widget.period,
        time: scheduledTime,
        isCompleted: newStatus,
      );
    } catch (e) {
      print('Error showing reminder notification: $e');
      // Fallback to scheduling without custom sound
      try {
        final now = DateTime.now(); // Redefine now for consistency
        var scheduledTime = widget.period == 'morning'
            ? DateTime(now.year, now.month, now.day, 8, 0)
            : widget.period == 'evening'
                ? DateTime(now.year, now.month, now.day, 18, 0)
                : DateTime(now.year, now.month, now.day, 22, 0);
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }
        await _notificationService.scheduleHabitNotification(
          habitId: widget.habit['id'],
          habitName: widget.habit['habit'],
          period: widget.period,
          time: scheduledTime,
          isCompleted: newStatus,
        );
      } catch (fallbackError) {
        print('Fallback scheduling failed: $fallbackError');
      }
    }
  }

  final allCompleted = await _checkAllRemindersCompleted();
  if (newStatus && allCompleted && mounted) {
    await _firestoreService.updateCheckedDates(
      widget.habit['id'],
      today,
      true,
    );
    _showDayFeedbackDialog();
  } else if (!newStatus && !allCompleted && mounted) {
    await _firestoreService.updateCheckedDates(
      widget.habit['id'],
      today,
      false,
    );
  }

  widget.onCompletionChanged();
}
  Future<bool> _checkAllRemindersCompleted() async {
    final doc =
        await _firestoreService.habitsCollection.doc(widget.habit['id']).get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return false;

    final morning = (data['morningReminder'] ?? false)
        ? (data['morningCompleted'] ?? false)
        : true;
    final evening = (data['eveningReminder'] ?? false)
        ? (data['eveningCompleted'] ?? false)
        : true;
    final night = (data['nightReminder'] ?? false)
        ? (data['nightCompleted'] ?? false)
        : true;

    return morning && evening && night;
  }

  bool _isDateInRange(DateTime date) {
    final start = widget.habit['startDate'] is Timestamp
        ? widget.habit['startDate'].toDate()
        : DateTime.now();
    return date.isAfter(start.subtract(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.habit['description'] ?? '';
    final category = widget.habit['category'] ?? 'Uncategorized';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: _isCompleted ? Colors.green : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit['habit'] ?? 'Unknown Habit',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Category: $category',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description.length > 50
                            ? '${description.substring(0, 50)}...'
                            : description,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditHabitPage(habit: widget.habit),
                      ),
                    );
                  } else if (value == 'delete') {
                    await _notificationService.cancelHabitNotification(
                      habitId: widget.habit['id'],
                      period: widget.period,
                    );
                    await _firestoreService.deleteHabit(widget.habit['id']);
                    widget.onCompletionChanged();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Checkbox(
                value: _isCompleted,
                onChanged: (bool? value) {
                  _toggleCompletion();
                },
                activeColor: Colors.green,
              ),
              IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ],
          ),
          if (_isExpanded)
            Column(
              children: [
                const SizedBox(height: 5),
                SizedBox(
                  width: double.infinity,
                  height: 350,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2010, 1, 1),
                    lastDay: DateTime.utc(2300, 12, 31),
                    focusedDay: DateTime.now(),
                    calendarFormat: CalendarFormat.month,
                    rowHeight: 40,
                    headerStyle: const HeaderStyle(
                      headerPadding: EdgeInsets.only(bottom: 10),
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 12, color: Colors.black),
                      weekendStyle: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.rectangle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.rectangle,
                      ),
                      withinRangeDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.rectangle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                    ),
                    eventLoader: (day) {
                      final checkedDates = widget.habit['checkedDates'] is List
                          ? (widget.habit['checkedDates'] as List)
                              .whereType<Timestamp>()
                              .map((e) => e.toDate())
                              .toList()
                          : <DateTime>[];
                      if (checkedDates.any((date) =>
                          date.day == day.day &&
                          date.month == day.month &&
                          date.year == day.year)) {
                        return ['Checked'];
                      }
                      return [];
                    },
                    selectedDayPredicate: (day) {
                      final checkedDates = widget.habit['checkedDates'] is List
                          ? (widget.habit['checkedDates'] as List)
                              .whereType<Timestamp>()
                              .map((e) => e.toDate())
                              .toList()
                          : <DateTime>[];
                      return checkedDates.any((date) =>
                          date.day == day.day &&
                          date.month == day.month &&
                          date.year == day.year);
                    },
                    enabledDayPredicate: (day) {
                      return _isDateInRange(day);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class EditHabitPage extends StatefulWidget {
  final Map<String, dynamic> habit;

  const EditHabitPage({super.key, required this.habit});

  @override
  _EditHabitPageState createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  late TextEditingController _habitController;
  late TextEditingController _descriptionController;
  DateTime? _startDate;
  bool _morningReminder = false;
  bool _eveningReminder = false;
  bool _nightReminder = false;
  String _category = '';
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _habitController = TextEditingController(text: widget.habit['habit'] ?? '');
    _descriptionController = TextEditingController(text: widget.habit['description'] ?? '');
    _startDate = widget.habit['startDate'] is Timestamp
        ? widget.habit['startDate'].toDate()
        : null;
    _morningReminder = widget.habit['morningReminder'] ?? false;
    _eveningReminder = widget.habit['eveningReminder'] ?? false;
    _nightReminder = widget.habit['nightReminder'] ?? false;
    _category = widget.habit['category'] ?? 'Uncategorized';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Habit'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _habitController,
              decoration: const InputDecoration(labelText: 'Habit'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: $_category',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter habit description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Date: ${_startDate != null ? DateFormat.yMMMd().format(_startDate!) : 'Not set'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Select Start Date'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reminders:',
                    style: TextStyle(fontSize: 18),
                  ),
                  CheckboxListTile(
                    title: const Text('Morning'),
                    value: _morningReminder,
                    onChanged: (bool? value) {
                      setState(() {
                        _morningReminder = value!;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  CheckboxListTile(
                    title: const Text('Evening'),
                    value: _eveningReminder,
                    onChanged: (bool? value) {
                      setState(() {
                        _eveningReminder = value!;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  CheckboxListTile(
                    title: const Text('Night'),
                    value: _nightReminder,
                    onChanged: (bool? value) {
                      setState(() {
                        _nightReminder = value!;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (_startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a start date')),
                    );
                    return;
                  }
                  if (widget.habit['morningReminder'] ?? false) {
                    await _notificationService.cancelHabitNotification(
                      habitId: widget.habit['id'],
                      period: 'morning',
                    );
                  }
                  if (widget.habit['eveningReminder'] ?? false) {
                    await _notificationService.cancelHabitNotification(
                      habitId: widget.habit['id'],
                      period: 'evening',
                    );
                  }
                  if (widget.habit['nightReminder'] ?? false) {
                    await _notificationService.cancelHabitNotification(
                      habitId: widget.habit['id'],
                      period: 'night',
                    );
                  }

                  await _firestoreService.updateHabit(
                    widget.habit['id'],
                    _habitController.text,
                    _category,
                    _startDate!,
                    _morningReminder,
                    _eveningReminder,
                    _nightReminder,
                    _descriptionController.text,
                  );

                  final now = DateTime.now();
                  if (_morningReminder) {
                    var morningTime = DateTime(now.year, now.month, now.day, 8, 0);
                    if (morningTime.isBefore(now)) {
                      morningTime = morningTime.add(const Duration(days: 1));
                    }
                    await _notificationService.scheduleHabitNotification(
                      habitId: widget.habit['id'],
                      habitName: _habitController.text,
                      period: 'morning',
                      time: morningTime,
                      isCompleted: false,
                    );
                  }
                  if (_eveningReminder) {
                    var eveningTime = DateTime(now.year, now.month, now.day, 18, 0);
                    if (eveningTime.isBefore(now)) {
                      eveningTime = eveningTime.add(const Duration(days: 1));
                    }
                    await _notificationService.scheduleHabitNotification(
                      habitId: widget.habit['id'],
                      habitName: _habitController.text,
                      period: 'evening',
                      time: eveningTime,
                      isCompleted: false,
                    );
                  }
                  if (_nightReminder) {
                    var nightTime = DateTime(now.year, now.month, now.day, 22, 0);
                    if (nightTime.isBefore(now)) {
                      nightTime = nightTime.add(const Duration(days: 1));
                    }
                    await _notificationService.scheduleHabitNotification(
                      habitId: widget.habit['id'],
                      habitName: _habitController.text,
                      period: 'night',
                      time: nightTime,
                      isCompleted: false,
                    );
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}