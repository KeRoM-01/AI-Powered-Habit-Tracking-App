// ignore_for_file: avoid_print, unused_local_variable

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ai_habit_tracking_app/services/firestore.dart';

class HabitRecommender {
  final FirestoreService _firestoreService = FirestoreService();
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> _loadModel() async {
    if (!_isModelLoaded) {
      try {
        _interpreter = await Interpreter.fromAsset('assets/habit_recommender.tflite');
        _isModelLoaded = true;
      } catch (e) {
        print('Error loading model: $e');
        throw Exception('Failed to load recommendation model');
      }
    }
  }

  Future<String> recommendHabit(String userId) async {
    try {
      await _loadModel();

      // Get user habits and categories
      List<Map<String, dynamic>> userHabits =
          await _firestoreService.getUserHabitsWithCategories(userId);
      if (userHabits.isEmpty) {
        return 'No habits found';
      }

      // Categories from addhabit.dart
      List<String> allCategories = [
        'Health & Fitness',
        'Personal Growth',
        'Daily Routine',
        'Unhealthy Lifestyle',
        'Financial',
        'Procrastination',
        'Digital Addiction',
        'Stress',
        'Sleep'
      ];

      // Encode user categories
      List<String> userCategories = userHabits.map((h) => h['category'] as String).toList();
      List<double> userVec = allCategories
          .map((cat) => userCategories.contains(cat) ? 1.0 : 0.0)
          .toList();

      // Get all available habits (simulate from addhabit.dart or fetch from Firestore)
      List<Map<String, String>> availableHabits = [
        {'name': 'Swimming', 'category': 'Health & Fitness'},
        {'name': 'Running', 'category': 'Health & Fitness'},
        {'name': 'Gym', 'category': 'Health & Fitness'},
        {'name': 'Yoga', 'category': 'Health & Fitness'},
        {'name': 'Walking', 'category': 'Health & Fitness'},
        {'name': 'Reading', 'category': 'Personal Growth'},
        {'name': 'Meditation', 'category': 'Personal Growth'},
        {'name': 'Journaling', 'category': 'Personal Growth'},
        {'name': 'Drinking Water', 'category': 'Daily Routine'},
        {'name': 'Brushing Teeth', 'category': 'Daily Routine'},
        {'name': 'Sleeping Early', 'category': 'Daily Routine'},
        {'name': 'Healthy Eating', 'category': 'Daily Routine'},
        {'name': 'Smoking', 'category': 'Unhealthy Lifestyle'},
        {'name': 'Junk Food', 'category': 'Unhealthy Lifestyle'},
        {'name': 'Binge Watching', 'category': 'Unhealthy Lifestyle'},
        {'name': 'Nail Biting', 'category': 'Unhealthy Lifestyle'},
        {'name': 'Overspending', 'category': 'Financial'},
        {'name': 'Delaying Tasks', 'category': 'Procrastination'},
        {'name': 'Excessive Social Media', 'category': 'Digital Addiction'},
        {'name': 'Overthinking', 'category': 'Stress'},
        {'name': 'Late Sleeping', 'category': 'Sleep'},
      ];

      // Filter out habits the user already has
      List<String> userHabitNames = userHabits.map((h) => h['habit'] as String).toList();
      availableHabits = availableHabits
          .where((h) => !userHabitNames.contains(h['name']))
          .toList();

      // Score each habit
      List<Map<String, dynamic>> recommendations = [];
      for (var habit in availableHabits) {
        List<double> habitVec = allCategories
            .map((cat) => habit['category'] == cat ? 1.0 : 0.0)
            .toList();
        List<double> input = userVec + habitVec;

        // Convert input to Float32List and reshape to [1, input.length]
        Float32List inputBuffer = Float32List.fromList(input);
        // Reshape input to [1, input.length] (e.g., [1, 18] if 9 categories for userVec + 9 for habitVec)
        List<List<double>> inputTensor = [input]; // Shape [1, input.length]

        // Prepare output tensor (assuming model outputs a single float score, shape [1, 1])
        Float32List outputBuffer = Float32List(1); // Shape [1]
        List<List<double>> outputTensor = [outputBuffer]; // Shape [1, 1]

        // Run inference
        try {
          _interpreter!.runForMultipleInputs([inputTensor], {0: outputTensor});
        } catch (e) {
          print('Inference error: $e');
          continue; // Skip this habit if inference fails
        }

        // Parse output
        double score = outputBuffer[0]; // Single float score

        recommendations.add({
          'name': habit['name'],
          'score': score,
        });
      }

      // Sort and select top recommendation
      recommendations.sort((a, b) => b['score'].compareTo(a['score']));
      if (recommendations.isEmpty) {
        return 'No new habits to recommend';
      }

      String recommendedHabit = recommendations.first['name'];
      await _firestoreService.saveRecommendedHabit(
        userHabitNames.join(', '),
        recommendedHabit,
      );
      return 'Try adding: $recommendedHabit';
    } catch (e) {
      print('Recommendation error: $e');
      return 'Failed to load recommendation';
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}