// ignore_for_file: file_names

// package com.example.ai_habit_tracking_app.notification;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging (FCM) notifications
class MyFirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes Firebase Messaging
  Future<void> initialize() async {
    // Request notification permissions from the user
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('🔔 Notification permission status: ${settings.authorizationStatus}');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("📩 Foreground Message Received: ${message.notification?.title}");
      }
      _showNotification(message);
    });

    // Handle background & terminated notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle when user taps on a notification (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("📲 User tapped notification: ${message.data}");
      }
    });

    // Get the Firebase Cloud Messaging (FCM) token
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("🔥 FCM Token: $token");
    }
  }

  /// Background message handler (required for notifications when the app is in the background)
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    if (kDebugMode) {
      print("📩 Background Message Received: ${message.notification?.title}");
    }
  }

  /// Displays a local notification when an FCM message is received
  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel_id',
      'AI Habit Tracker Notifications',
      channelDescription: 'Notifications for habit tracking reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "New Notification",
      message.notification?.body ?? "You have a new message",
      platformChannelSpecifics,
    );
  }
}
