// ignore_for_file: avoid_print

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'firestore.dart';

class AdviceGenerator {
  final FirestoreService _firestoreService;
  Interpreter? _interpreter;

  AdviceGenerator(this._firestoreService);

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/advice_model.tflite');
    } catch (e) {
      print('Error loading TFLite model: $e');
    }
  }

  Future<String> generateAdvice({
    required String habit,
    required String category,
    required int streak,
    required double completionRate,
    required bool isGoodHabit,
    String? context,
  }) async {
    try {
      // Check cached advice
      final cachedAdvice = await _firestoreService.getCachedAdvice(habit);
      if (cachedAdvice != null &&
          DateTime.now().difference((cachedAdvice['timestamp'] as Timestamp).toDate()).inHours < 24) {
        print('Using cached advice for $habit');
        return cachedAdvice['advice'] as String;
      }

      // Fetch templates
      final templates = await _firestoreService.getAdviceTemplates(category, isGoodHabit);
      if (templates.isEmpty) {
        final fallbackAdvice = _getFallbackAdvice(habit, isGoodHabit);
        await _firestoreService.saveGeneratedAdvice(habit, fallbackAdvice, category, isGoodHabit);
        return fallbackAdvice;
      }

      // Rotate templates to avoid repetition
      final template = templates[Random().nextInt(templates.length)]['template'] as String;

      // Load TFLite model if not loaded
      if (_interpreter == null) {
        await _loadModel();
      }

      // Generate personalized advice
      String personalizedAdvice;
      if (_interpreter != null) {
        personalizedAdvice = await _personalizeAdviceWithTFLite(
          template: template,
          habit: habit,
          streak: streak,
          completionRate: completionRate,
          context: context ?? 'neutral',
          isGoodHabit: isGoodHabit,
        );
      } else {
        personalizedAdvice = _personalizeAdviceFallback(
          template: template,
          habit: habit,
          streak: streak,
          completionRate: completionRate,
          context: context,
          isGoodHabit: isGoodHabit,
        );
      }

      // Save the generated advice
      await _firestoreService.saveGeneratedAdvice(habit, personalizedAdvice, category, isGoodHabit);
      return personalizedAdvice;
    } catch (e) {
      print('Error generating advice: $e');
      final fallbackAdvice = _getFallbackAdvice(habit, isGoodHabit);
      await _firestoreService.saveGeneratedAdvice(habit, fallbackAdvice, category, isGoodHabit);
      return fallbackAdvice;
    }
  }

  Future<String> _personalizeAdviceWithTFLite({
    required String template,
    required String habit,
    required int streak,
    required double completionRate,
    required String context,
    required bool isGoodHabit,
  }) async {
    if (_interpreter == null) {
      return _personalizeAdviceFallback(
        template: template,
        habit: habit,
        streak: streak,
        completionRate: completionRate,
        context: context,
        isGoodHabit: isGoodHabit,
      );
    }

    // Prepare input for TFLite model
    final input = [
      template,
      habit,
      streak.toString(),
      completionRate.toString(),
      context,
      isGoodHabit.toString(),
    ];
    final output = List.filled(1, '').reshape([1, 1]);
    _interpreter!.run(input, output);
    return output[0][0];
  }

  String _personalizeAdviceFallback({
    required String template,
    required String habit,
    required int streak,
    required double completionRate,
    String? context,
    required bool isGoodHabit,
  }) {
    String advice = template.replaceAll('[habit]', habit.toLowerCase());

    // Adjust tone based on habit type and context
    if (isGoodHabit) {
      if (context != null && context.contains('low')) {
        advice = 'Feeling down? A quick $advice can lift your spirits!';
      } else if (streak > 5) {
        advice = 'Amazing $streak-day streak! Keep up with $advice';
      }
    } else {
      if (context != null && context.contains('low')) {
        advice = 'Tough day? Try cutting back on $advice to feel better.';
      } else if (completionRate > 0.7) {
        advice = 'You’re slipping on $habit. $advice';
      } else {
        advice = 'Great progress! $advice';
      }
    }

    if (completionRate < 0.5 && isGoodHabit) {
      advice += ' Stay consistent to see results!';
    }

    return advice;
  }

  String _getFallbackAdvice(String habit, bool isGoodHabit) {
    final goodHabitFallbacks = [
      'Stay consistent with your $habit to build a strong routine!',
      'Try $habit today to boost your progress!',
      'Small steps with $habit lead to big wins!',
    ];
    final badHabitFallbacks = [
      'Cut back on $habit to improve your day!',
      'Replace $habit with a positive action today!',
      'Take a break from $habit to feel better!',
    ];
    final fallbacks = isGoodHabit ? goodHabitFallbacks : badHabitFallbacks;
    return fallbacks[Random().nextInt(fallbacks.length)].replaceAll('habit', habit.toLowerCase());
  }

  void dispose() {
    _interpreter?.close();
  }
}