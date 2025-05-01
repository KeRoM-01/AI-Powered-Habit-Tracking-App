// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_habit_tracking_app/pages/addhabit2.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

class UserAddhabit extends StatefulWidget {
  final String? userId; // Optional userId parameter

  const UserAddhabit({super.key, this.userId});

  @override
  State<UserAddhabit> createState() => _UserAddhabitState();
}

class _UserAddhabitState extends State<UserAddhabit> {
  final Map<String, List<Map<String, String>>> habits = {
    'Good Habits': [
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
    ],
    'Bad Habits': [
      {'name': 'Smoking', 'category': 'Unhealthy Lifestyle'},
      {'name': 'Junk Food', 'category': 'Unhealthy Lifestyle'},
      {'name': 'Binge Watching', 'category': 'Unhealthy Lifestyle'},
      {'name': 'Nail Biting', 'category': 'Unhealthy Lifestyle'},
      {'name': 'Overspending', 'category': 'Financial'},
      {'name': 'Delaying Tasks', 'category': 'Procrastination'},
      {'name': 'Excessive Social Media', 'category': 'Digital Addiction'},
      {'name': 'Overthinking', 'category': 'Stress'},
      {'name': 'Late Sleeping', 'category': 'Sleep'},
    ],
  };
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 99, 71, 224),
        centerTitle: true,
        title: Text(
          'A D D  H A B I T S',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: habits.entries.map((category) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 40),
                        child: Text(
                          category.key,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: category.value
                            .where((habit) =>
                                habit['name']!.toLowerCase().contains(query.toLowerCase()))
                            .map((habit) => ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                    minimumSize: Size(100, 50),
                                  ),
                                  label: Text(
                                    habit['name']!,
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  icon: Icon(_getIconForHabit(habit['name']!)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddHabitDetailsPage(
                                          habit: habit['name']!,
                                          category: habit['category']!, // Pass category
                                          userId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ))
              .toList(),
            ),
          ),
          buildFloatingSearchBar(),
        ],
      ),
    );
  }

  Widget buildFloatingSearchBar() {
    return FloatingSearchBar(
      hint: 'Search...',
      scrollPadding: EdgeInsets.only(top: 16, bottom: 20),
      transitionDuration: Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: BouncingScrollPhysics(),
      axisAlignment: 0.0,
      openAxisAlignment: 0.0,
      width: 600,
      debounceDelay: Duration(milliseconds: 500),
      onQueryChanged: (query) {
        setState(() {
          this.query = query;
        });
      },
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction.searchToClear(),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: habits.values
                  .expand((list) => list)
                  .where((habit) =>
                      habit['name']!.toLowerCase().contains(query.toLowerCase()))
                  .map((habit) => ListTile(
                        title: Text(habit['name']!),
                        onTap: () {
                          setState(() {
                            query = habit['name']!;
                          });

                          if (habit['name']!.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddHabitDetailsPage(
                                  habit: habit['name']!,
                                  category: habit['category']!, // Pass category
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          }

                          FloatingSearchBar.of(context)?.close();
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForHabit(String habit) {
    if (habit.contains('Swimming')) return Icons.pool;
    if (habit.contains('Reading')) return Icons.book;
    if (habit.contains('Running')) return Icons.directions_run;
    if (habit.contains('Meditation')) return Icons.self_improvement;
    if (habit.contains('Smoking')) return Icons.smoking_rooms;
    if (habit.contains('Drinking Water')) return Icons.local_drink;
    if (habit.contains('Sleeping Early')) return Icons.nights_stay;
    if (habit.contains('Healthy Eating')) return Icons.restaurant;
    if (habit.contains('Brushing Teeth')) return Icons.brush;
    if (habit.contains('Gym')) return Icons.fitness_center;
    if (habit.contains('Yoga')) return Icons.self_improvement;
    if (habit.contains('Walking')) return Icons.directions_walk;
    if (habit.contains('Journaling')) return Icons.edit;
    if (habit.contains('Junk Food')) return Icons.fastfood_outlined;
    if (habit.contains('Binge Watching')) return Icons.tv;
    if (habit.contains('Nail Biting')) return Icons.gesture;
    if (habit.contains('Overspending')) return Icons.money_off;
    if (habit.contains('Excessive Social Media')) return Icons.phone_android;
    if (habit.contains('Overthinking')) return Icons.psychology;
    if (habit.contains('Late Sleeping')) return Icons.nightlight_round;
    return Icons.help;
  }
}