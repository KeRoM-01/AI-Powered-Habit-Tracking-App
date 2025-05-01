// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_habit_tracking_app/auth.dart';
import 'package:ai_habit_tracking_app/firebase_options.dart';
import 'package:ai_habit_tracking_app/screens/home_screen.dart';
import 'package:ai_habit_tracking_app/screens/LoginScreen.dart';
import 'package:ai_habit_tracking_app/screens/signup_screen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background Message Handler (Runs when the app is terminated or in background)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background Message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.setLanguageCode('en');

  // ✅ Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request Notification Permission (For iOS & Android 13+)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('🔔 User granted notification permission: ${settings.authorizationStatus}');

  // ✅ Get FCM Token (Copy this to test push notifications)
  try {
    String? token = await messaging.getToken();
    print("📲 Firebase FCM Token: $token");
  } catch (e) {
    print("❌ Error retrieving FCM token: $e");
  }

  // ✅ Listen for Foreground Messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground Message: ${message.notification?.title}");
    print("📩 Message Data: ${message.data}");
    showNotification(message);
  });

  // ✅ Register Background Message Handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ✅ Initialize Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ Create Notification Channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'channel_id', // ID
    'channel_name', // Name
    description: 'Notification channel for habit tracking', // Description
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  runApp(const MyApp());
}

/// ✅ Show Local Notification when FCM Message is Received
Future<void> showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    channelDescription: 'Notification channel for habit tracking',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
    message.notification?.title ?? "New Notification",
    message.notification?.body ?? "You have a new message",
    platformChannelSpecifics,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Habit Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/loginScreen',
      routes: {
        '/': (context) => const Auth(),
        '/homeScreen': (context) => HomeScreen(),
        '/signupScreen': (context) => const SignupScreen(),
        '/loginScreen': (context) => const LoginScreen(),
      },
      builder: EasyLoading.init(),
    );
  }
}
