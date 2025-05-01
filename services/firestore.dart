// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get habitsCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('habits');

  CollectionReference get adviceTemplatesCollection =>
      FirebaseFirestore.instance.collection('advice_templates');

  CollectionReference get userAdviceCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('advice');

  Future<void> addHabit(
    String habit,
    String category,
    DateTime startDate,
    bool morningReminder,
    bool eveningReminder,
    bool nightReminder,
    String description,
  ) async {
    await habitsCollection.add({
      'habit': habit,
      'category': category,
      'startDate': startDate,
      'morningReminder': morningReminder,
      'eveningReminder': eveningReminder,
      'nightReminder': nightReminder,
      'description': description,
      'morningCompleted': false,
      'eveningCompleted': false,
      'nightCompleted': false,
      'checkedDates': [],
      'lastCheckedDate': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getHabits() {
    return habitsCollection.snapshots();
  }

  Future<List<Map<String, dynamic>>> getProgressLogs() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('progress_logs')
        .doc(userId)
        .collection('logs')
        .orderBy('date')
        .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> addProgressLog(DateTime date, int progress) async {
    await FirebaseFirestore.instance
        .collection('progress_logs')
        .doc(userId)
        .collection('logs')
        .add({
      'date': Timestamp.fromDate(date),
      'progress': progress,
    });
  }

  Future<void> deleteProgressLog(String logId) async {
    await FirebaseFirestore.instance
        .collection('progress_logs')
        .doc(userId)
        .collection('logs')
        .doc(logId)
        .delete();
  }

  Future<void> deleteHabit(String habitId) async {
    await habitsCollection.doc(habitId).delete();
  }

  Future<void> updateReminderCompletion(String habitId, String period, bool isCompleted) async {
    await habitsCollection.doc(habitId).update({
      '${period}Completed': isCompleted,
      'lastCheckedDate': Timestamp.now(),
    });
  }

  Future<void> updateCheckedDates(String habitId, DateTime date, bool isCompleted) async {
    if (isCompleted) {
      await habitsCollection.doc(habitId).update({
        'checkedDates': FieldValue.arrayUnion([Timestamp.fromDate(date)]),
      });
    } else {
      await habitsCollection.doc(habitId).update({
        'checkedDates': FieldValue.arrayRemove([Timestamp.fromDate(date)]),
      });
    }
  }

  Future<void> updateHabit(
    String habitId,
    String habit,
    String category,
    DateTime startDate,
    bool morningReminder,
    bool eveningReminder,
    bool nightReminder,
    String description,
  ) async {
    await habitsCollection.doc(habitId).update({
      'habit': habit,
      'category': category,
      'startDate': startDate,
      'morningReminder': morningReminder,
      'eveningReminder': eveningReminder,
      'nightReminder': nightReminder,
      'description': description,
    });
  }

  Future<void> addDayFeedback(DateTime dateTime, String feeling, String emoji) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('day_feedback')
        .add({
      'date': Timestamp.fromDate(dateTime),
      'feeling': feeling,
      'emoji': emoji,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getRecentMood() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('day_feedback')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first['feeling'] as String? : null;
  }

  Future<List<String>> getUserSelectedHabits(String userId) async {
    final querySnapshot = await habitsCollection.get();
    return querySnapshot.docs
        .map((doc) => doc['habit'] as String)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUserHabitsWithCategories(String userId) async {
    final querySnapshot = await habitsCollection.get();
    return querySnapshot.docs
        .map((doc) => {
              'habit': doc['habit'] as String,
              'category': doc['category'] as String,
              'checkedDates': (doc['checkedDates'] as List<dynamic>? ?? [])
                  .map((ts) => (ts as Timestamp).toDate())
                  .toList(),
              'morningCompleted': doc['morningCompleted'] as bool? ?? false,
              'eveningCompleted': doc['eveningCompleted'] as bool? ?? false,
              'nightCompleted': doc['nightCompleted'] as bool? ?? false,
            })
        .toList();
  }

  Future<void> saveRecommendedHabit(String habit, String recommendedHabit) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recommendations')
        .add({
      'habit': habit,
      'recommendedHabit': recommendedHabit,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getAdviceTemplates(String category, bool isGoodHabit) async {
    final querySnapshot = await adviceTemplatesCollection
        .where('category', isEqualTo: category)
        .where('isGoodHabit', isEqualTo: isGoodHabit)
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> saveGeneratedAdvice(
      String habit, String advice, String category, bool isGoodHabit) async {
    await userAdviceCollection.add({
      'habit': habit,
      'advice': advice,
      'category': category,
      'isGoodHabit': isGoodHabit,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserAdvice() async {
    final querySnapshot = await userAdviceCollection
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>?> getCachedAdvice(String habit) async {
    final snapshot = await userAdviceCollection
        .where('habit', isEqualTo: habit)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first.data() as Map<String, dynamic> : null;
  }
}