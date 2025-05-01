import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ai_habit_tracking_app/services/firestore.dart';
import 'package:ai_habit_tracking_app/services/advice_generator.dart';


// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously

class UserDashboard extends StatefulWidget {
  final String userId;

  const UserDashboard({super.key, required this.userId});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<FlSpot> _dailyCompletionSpots = [];
  List<BarChartGroupData> _habitCompletionBars = [];
  List<PieChartSectionData> _habitCategorySections = [];
  List<String> _habitNames = [];
  List<Map<String, dynamic>> _userAdvice = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedTimeRange = 'Last 7 Days';
  final List<String> _timeRanges = [
    'Last 7 Days',
    'Last Month',
    'Last 6 Months',
    'Last Year'
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final AdviceGenerator _adviceGenerator = AdviceGenerator(FirestoreService());

  final List<String> _positiveHabits = [
    'Swimming', 'Running', 'Gym', 'Reading', 'Meditation', 'Drinking Water',
    'Brushing Teeth', 'Sleeping Early', 'Yoga', 'Journaling', 'Walking', 'Healthy Eating'
  ];
  final List<String> _negativeHabits = [
    'Smoking', 'Junk Food', 'Delaying Tasks', 'Excessive Social Media', 'Overthinking',
    'Binge Watching', 'Nail Biting', 'Overspending', 'Late Sleeping'
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _generateAndLoadAdvice();
  }

  @override
  void dispose() {
    _adviceGenerator.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('habits')
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No habits found. Add some habits to see your progress!';
        });
        return;
      }

      final dailySpots = <FlSpot>[];
      final habitBars = <BarChartGroupData>[];
      final habitNames = <String>[];
      int positiveCompletions = 0, negativeCompletions = 0;

      final now = DateTime.now();
      DateTime startDate;
      int intervals;
      String intervalType;

      switch (_selectedTimeRange) {
        case 'Last 7 Days':
          startDate = now.subtract(Duration(days: 7));
          intervals = 7;
          intervalType = 'day';
          break;
        case 'Last Month':
          startDate = now.subtract(Duration(days: 30));
          intervals = 30;
          intervalType = 'day';
          break;
        case 'Last 6 Months':
          startDate = now.subtract(Duration(days: 180));
          intervals = 26;
          intervalType = 'week';
          break;
        case 'Last Year':
          startDate = now.subtract(Duration(days: 365));
          intervals = 12;
          intervalType = 'month';
          break;
        default:
          startDate = now.subtract(Duration(days: 7));
          intervals = 7;
          intervalType = 'day';
      }

      final completions = List<int>.filled(intervals, 0);
      for (var i = 0; i < intervals; i++) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final checkedDates = (data['checkedDates'] as List<dynamic>? ?? [])
              .map((ts) => (ts as Timestamp).toDate())
              .toList();

          if (intervalType == 'day') {
            final date = startDate.add(Duration(days: i));
            if (checkedDates.any((d) =>
                d.year == date.year && d.month == date.month && d.day == date.day)) {
              completions[i]++;
            }
          } else if (intervalType == 'week') {
            final weekStart = startDate.add(Duration(days: i * 7));
            final weekEnd = weekStart.add(Duration(days: 7));
            if (checkedDates.any((d) => d.isAfter(weekStart) && d.isBefore(weekEnd))) {
              completions[i]++;
            }
          } else if (intervalType == 'month') {
            final monthStart = DateTime(startDate.year, startDate.month + i, 1);
            final monthEnd = DateTime(startDate.year, startDate.month + i + 1, 1);
            if (checkedDates.any((d) => d.isAfter(monthStart) && d.isBefore(monthEnd))) {
              completions[i]++;
            }
          }
        }
        dailySpots.add(FlSpot(i.toDouble(), completions[i].toDouble()));
      }

      int habitIndex = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final habitName = data['habit'] as String;
        final checkedDates = (data['checkedDates'] as List<dynamic>? ?? [])
            .map((ts) => (ts as Timestamp).toDate())
            .toList();
        final startDate = (data['startDate'] as Timestamp?)?.toDate() ?? now;
        final endDate = (data['endDate'] as Timestamp?)?.toDate() ?? now;
        final morningCompleted = data['morningCompleted'] as bool? ?? false;
        final eveningCompleted = data['eveningCompleted'] as bool? ?? false;
        final nightCompleted = data['nightCompleted'] as bool? ?? false;

        int completionCount = checkedDates
            .where((date) => date.isAfter(startDate) && date.isBefore(endDate))
            .length;
        if (morningCompleted) completionCount++;
        if (eveningCompleted) completionCount++;
        if (nightCompleted) completionCount++;

        habitBars.add(BarChartGroupData(
          x: habitIndex,
          barRods: [
            BarChartRodData(
              toY: completionCount.toDouble(),
              color: Colors.deepPurple,
              width: MediaQuery.of(context).size.width / (querySnapshot.docs.length * 2),
            ),
          ],
        ));

        habitNames.add(habitName);

        if (_positiveHabits.contains(habitName)) {
          positiveCompletions += completionCount;
        } else if (_negativeHabits.contains(habitName)) {
          negativeCompletions += completionCount;
        }

        habitIndex++;
      }

      final totalCompletions = positiveCompletions + negativeCompletions;
      final pieSections = <PieChartSectionData>[];
      if (totalCompletions > 0) {
        if (positiveCompletions > 0) {
          pieSections.add(PieChartSectionData(
            value: positiveCompletions.toDouble(),
            title: 'Positive\n${((positiveCompletions / totalCompletions) * 100).toStringAsFixed(1)}%',
            color: Colors.green,
            radius: 50,
          ));
        }
        if (negativeCompletions > 0) {
          pieSections.add(PieChartSectionData(
            value: negativeCompletions.toDouble(),
            title: 'Negative\n${((negativeCompletions / totalCompletions) * 100).toStringAsFixed(1)}%',
            color: Colors.red,
            radius: 50,
          ));
        }
      }

      setState(() {
        _dailyCompletionSpots = dailySpots;
        _habitCompletionBars = habitBars;
        _habitCategorySections = pieSections;
        _habitNames = habitNames;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }

  Future<void> _generateAndLoadAdvice() async {
    try {
      final habits = await _firestoreService.getUserHabitsWithCategories(widget.userId);
      print('Habits retrieved: $habits');
      if (habits.isEmpty) {
        print('No habits found, skipping advice generation');
        return;
      }

      final mood = await _firestoreService.getRecentMood();
      print('User mood: $mood');

      for (var habitData in habits) {
        final habit = habitData['habit'] as String;
        final category = habitData['category'] as String;
        final checkedDates = habitData['checkedDates'] as List<DateTime>;
        final streak = _calculateStreak(checkedDates);
        final completionRate = _calculateCompletionRate(habitData);
        final isGoodHabit = _positiveHabits.contains(habit);
        print('Generating advice for $habit: streak=$streak, completionRate=$completionRate, isGoodHabit=$isGoodHabit');

        await _adviceGenerator.generateAdvice(
          habit: habit,
          category: category,
          streak: streak,
          completionRate: completionRate,
          isGoodHabit: isGoodHabit,
          context: mood ?? 'neutral',
        );
      }

      var advice = await _firestoreService.getUserAdvice();
      print('Initial advice loaded: $advice');
      if (advice.isEmpty && habits.isNotEmpty) {
        print('No advice found, retrying generation');
        for (var habitData in habits) {
          final habit = habitData['habit'] as String;
          final category = habitData['category'] as String;
          final checkedDates = habitData['checkedDates'] as List<DateTime>;
          final streak = _calculateStreak(checkedDates);
          final completionRate = _calculateCompletionRate(habitData);
          final isGoodHabit = _positiveHabits.contains(habit);
          await _adviceGenerator.generateAdvice(
            habit: habit,
            category: category,
            streak: streak,
            completionRate: completionRate,
            isGoodHabit: isGoodHabit,
            context: mood ?? 'neutral',
          );
        }
        advice = await _firestoreService.getUserAdvice();
        print('Advice after retry: $advice');
      }

      setState(() {
        _userAdvice = advice;
      });
    } catch (e) {
      print('Error generating advice: $e');
    }
  }

  int _calculateStreak(List<DateTime> checkedDates) {
    if (checkedDates.isEmpty) return 0;
    final sortedDates = checkedDates..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime current = DateTime.now();
    for (var date in sortedDates) {
      if (date.day == current.day &&
          date.month == current.month &&
          date.year == current.year) {
        streak++;
        current = current.subtract(Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  double _calculateCompletionRate(Map<String, dynamic> habitData) {
    final checkedDates = habitData['checkedDates'] as List<DateTime>;
    final morningCompleted = habitData['morningCompleted'] as bool;
    final eveningCompleted = habitData['eveningCompleted'] as bool;
    final nightCompleted = habitData['nightCompleted'] as bool;
    int totalChecks = checkedDates.length;
    if (morningCompleted) totalChecks++;
    if (eveningCompleted) totalChecks++;
    if (nightCompleted) totalChecks++;
    final totalPossible = (DateTime.now().difference(checkedDates.isNotEmpty ? checkedDates.first : DateTime.now()).inDays + 1) * 3;
    return totalPossible > 0 ? totalChecks / totalPossible : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxYLine = _dailyCompletionSpots.isNotEmpty
        ? (_dailyCompletionSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1)
        : 10.0;
    final maxYBar = _habitCompletionBars.isNotEmpty
        ? (_habitCompletionBars
                .map((e) => e.barRods.first.toY)
                .reduce((a, b) => a > b ? a : b) +
            1)
        : 10.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 99, 71, 224),
        centerTitle: true,
        title: Text(
          'D A S H B O A R D',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tips for You Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tips for You',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                            onPressed: _generateAndLoadAdvice,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _userAdvice.isEmpty
                          ? Center(
                              child: Text(
                                'No tips available yet. Add habits to get started!',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                              ),
                            )
                          : SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _userAdvice.length,
                                itemBuilder: (context, index) {
                                  final advice = _userAdvice[index];
                                  final isGoodHabit = advice['isGoodHabit'] as bool;
                                  return Container(
                                    width: screenWidth * 0.7,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isGoodHabit
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          advice['habit'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isGoodHabit ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          advice['advice'],
                                          style: GoogleFonts.poppins(fontSize: 12),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                      const SizedBox(height: 20),

                      // Daily Completion Trend with Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Completion Trend',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedTimeRange,
                            items: _timeRanges.map((range) {
                              return DropdownMenuItem<String>(
                                value: range,
                                child: Text(
                                  range,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedTimeRange = value;
                                });
                                _loadDashboardData();
                              }
                            },
                            underline: Container(),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        width: screenWidth,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: _dailyCompletionSpots,
                                isCurved: true,
                                barWidth: 3,
                                color: Colors.blueAccent,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blueAccent.withOpacity(0.3),
                                ),
                              ),
                            ],
                            maxY: maxYLine,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                axisNameWidget: Text(
                                  'Completions',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    );
                                  },
                                  reservedSize: 20,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                axisNameWidget: Text(
                                  'Date',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final now = DateTime.now();
                                    switch (_selectedTimeRange) {
                                      case 'Last 7 Days':
                                        final date = now.subtract(
                                            Duration(days: 6 - value.toInt()));
                                        return Text(
                                          DateFormat('MM/dd').format(date),
                                          style: GoogleFonts.poppins(fontSize: 8),
                                        );
                                      case 'Last Month':
                                        final date = now.subtract(
                                            Duration(days: 29 - value.toInt()));
                                        return Text(
                                          DateFormat('MM/dd').format(date),
                                          style: GoogleFonts.poppins(fontSize: 8),
                                        );
                                      case 'Last 6 Months':
                                        final weekStart = now.subtract(
                                            Duration(days: (25 - value.toInt()) * 7));
                                        return Text(
                                          DateFormat('MM/dd').format(weekStart),
                                          style: GoogleFonts.poppins(fontSize: 8),
                                        );
                                      case 'Last Year':
                                        final monthStart = DateTime(
                                            now.year, now.month - 11 + value.toInt(), 1);
                                        return Text(
                                          DateFormat('MMM').format(monthStart),
                                          style: GoogleFonts.poppins(fontSize: 8),
                                        );
                                      default:
                                        return const Text('');
                                    }
                                  },
                                  reservedSize: 30,
                                  interval: _selectedTimeRange == 'Last 7 Days'
                                      ? 1
                                      : _selectedTimeRange == 'Last Month'
                                          ? 5
                                          : _selectedTimeRange == 'Last 6 Months'
                                              ? 4
                                              : 1,
                                ),
                              ),
                              topTitles:
                                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles:
                                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            gridData: FlGridData(show: true),
                            extraLinesData: ExtraLinesData(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bar Chart: Habit Completion Comparison
                      Text(
                        'Habit Completion Comparison',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        width: screenWidth,
                        child: BarChart(
                          BarChartData(
                            barGroups: _habitCompletionBars,
                            maxY: maxYBar,
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                axisNameWidget: Text(
                                  'Habits',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    return Text(
                                      index < _habitNames.length ? _habitNames[index] : '',
                                      style: GoogleFonts.poppins(fontSize: 8),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                  reservedSize: 30,
                                  interval: 1,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                axisNameWidget: Text(
                                  'Completions',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles:
                                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles:
                                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            gridData: FlGridData(show: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pie Chart: Habit Category Distribution
                      Text(
                        'Habit Category Distribution',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        width: screenWidth,
                        child: _habitCategorySections.isEmpty
                            ? Center(
                                child: Text(
                                  'No completion data available',
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sections: _habitCategorySections,
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend(color: Colors.green, label: 'Positive'),
                          const SizedBox(width: 20),
                          _buildLegend(color: Colors.red, label: 'Negative'),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }
}