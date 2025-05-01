// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_habit_tracking_app/chats/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UserCommunity extends StatefulWidget {
  const UserCommunity({super.key});

  @override
  State<UserCommunity> createState() => _UserCommunityState();
}

class _UserCommunityState extends State<UserCommunity> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _subscribeToChatMessages();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _subscribeToChatMessages() {
    for (String habit in habits) {
      FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(habit)
          .collection('messages')
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            _showNotification(habit, change.doc.data()?['message'] ?? 'New message');
          }
        }
      });
    }
  }

  Future<void> _showNotification(String habit, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      habit.hashCode,
      'New Message in $habit',
      message,
      platformDetails,
    );
  }

  final List<String> habits = [
    'Swimming',
    'Reading',
    'Running',
    'Meditation',
    'Smoking',
    'Drinking Water',
    'Sleeping Early',
    'Healthy Eating',
    'Brushing Teeth',
    'Gym',
    'Yoga',
    'Walking',
    'Journaling',
    'Junk Food',
    'Binge Watching',
    'Nail Biting',
    'Overspending',
    'Excessive Social Media',
    'Overthinking',
    'Late Sleeping',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Text('C O M M U N I T Y', style: GoogleFonts.poppins().copyWith(color: Colors.white)),
      ),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (context, index) {
          var habit = habits[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(
                habit,
                style: GoogleFonts.poppins().copyWith(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(chatRoomId: habit, chatRoomName: habit),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text('Chat', style: GoogleFonts.poppins().copyWith(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}