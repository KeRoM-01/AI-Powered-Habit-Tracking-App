// ignore_for_file: avoid_print

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> init() async {
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Request permissions
  Future<void> requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Show instant notification for habit completion or reminder
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_tracker_channel',
            'Habit Tracker Notifications',
            channelDescription: 'Notifications for habit reminders and completion',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      print('Error showing instant notification: $e');
      // Fallback to default sound
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_tracker_channel',
            'Habit Tracker Notifications',
            channelDescription: 'Notifications for habit reminders and completion',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  // Schedule notification for a habit
  Future<void> scheduleHabitNotification({
    required String habitId,
    required String habitName,
    required String period,
    required DateTime time,
    required bool isCompleted,
  }) async {
    if (isCompleted) return; // Skip if habit is already completed

    final notificationId = generateNotificationId(habitId, period);
    final message = _getSupportMessage(habitName);

    // Adjust time if it has already passed today
    var scheduledTime = tz.TZDateTime.from(time, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Habit Reminder: $habitName',
        message,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_tracker_channel',
            'Habit Tracker Notifications',
            channelDescription: 'Notifications for habit reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Schedule daily
      );
    } catch (e) {
      print('Error scheduling notification: $e');
      // Fallback to default sound
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Habit Reminder: $habitName',
        message,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_tracker_channel',
            'Habit Tracker Notifications',
            channelDescription: 'Notifications for habit reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // Cancel notification for a habit
  Future<void> cancelHabitNotification({
    required String habitId,
    required String period,
  }) async {
    final notificationId = generateNotificationId(habitId, period);
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Generate unique notification ID
  int generateNotificationId(String habitId, String period) {
    final periodCode = period == 'morning' ? '1' : period == 'evening' ? '2' : '3';
    return (habitId.hashCode.toString() + periodCode).hashCode % 2147483647;
  }

  // Get motivational support message
  String _getSupportMessage(String habitName) {
    final messages = {
      'Swimming': 'Dive into your Swimming routine! 🏊 Keep making waves!',
      'Running': 'Lace up for Running! 🏃 Every step counts!',
      'Gym': 'Hit the Gym! 💪 Your strength is growing!',
      'Reading': 'Open a book for Reading! 📚 A little every day goes a long way!',
      'Meditation': 'Find calm with Meditation! 🧘 Take a moment for yourself.',
      'Drinking Water': 'Stay hydrated with Drinking Water! 💧 Keep it flowing!',
      'Brushing Teeth': 'Keep smiling with Brushing Teeth! 😁 Shine bright!',
      'Sleeping Early': 'Rest up with Sleeping Early! 🌙 Recharge for tomorrow!',
      'Smoking': 'You’re stronger than Smoking! 💨 Choose health today!',
      'Junk Food': 'Skip the Junk Food! 🥐 Fuel your body with goodness!',
      'Delaying Tasks': 'Tackle tasks now! ⏰ No more Delaying Tasks!',
      'Excessive Social Media': 'Unplug from Social Media! 📱 Focus on what matters!',
      'Overthinking': 'Let go of Overthinking! 🧠 Take it one step at a time!',
    };
    return messages[habitName] ??
        'Stay focused on $habitName! You’ve got this! 🌟';
  }
}