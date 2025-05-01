// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ai_habit_tracking_app/pages/addhabit.dart';
import 'package:ai_habit_tracking_app/pages/community.dart';
import 'package:ai_habit_tracking_app/pages/dashboard.dart';
import 'package:ai_habit_tracking_app/pages/home.dart';
import 'package:ai_habit_tracking_app/pages/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    UserHome(),
    UserDashboard(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    UserAddhabit(),
    UserCommunity(),
    UserProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    // Get screen size using MediaQuery
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive sizes
    final navBarHeight = screenHeight * 0.08; // 8% of screen height, min 50, max 70
    final iconSize = screenWidth * 0.06; // 6% of screen width for icons
    final addIconSize = screenWidth * 0.1; // Larger size for the 'add' icon

    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(255, 210, 235, 255),
        animationDuration: Duration(milliseconds: 500),
        height: navBarHeight.clamp(50, 70), // Responsive height
        index: _selectedIndex,
        onTap: _navigateBottomBar,
        items: [
          Icon(Icons.home, size: iconSize),
          Icon(Icons.analytics, size: iconSize),
          Icon(Icons.add, size: addIconSize), // Larger size for 'add' icon
          Icon(Icons.diversity_3_rounded, size: iconSize),
          Icon(Icons.person, size: iconSize),
        ],
      ),
    );
  }
}