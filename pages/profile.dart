// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously, unnecessary_string_interpolations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_habit_tracking_app/ProfileSubPages/aboutus.dart';
import 'package:ai_habit_tracking_app/ProfileSubPages/profileSetting.dart';
import 'package:ai_habit_tracking_app/ProfileSubPages/setting.dart';
import 'package:ai_habit_tracking_app/screens/LoginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class UserProfile extends StatefulWidget {
  final String? userId; // Optional userId parameter

  const UserProfile({super.key, this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String userId = widget.userId ?? user?.uid ?? '';

      if (userId.isNotEmpty) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(userId).get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'] ?? 'User';
          });
        } else {
          setState(() {
            _userName = 'User';
          });
        }
      }
    } catch (e) {
      setState(() {
        _userName = 'User';
      });
      debugPrint('Error loading user name: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      EasyLoading.show(status: 'Logging out...');
      await FirebaseAuth.instance.signOut();
      EasyLoading.dismiss();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.fromLTRB(15, 50, 15, 20),
        children: [
          CircleAvatar(
            radius: 100,
            child: Image.asset('assets/profile.png'),
          ),
          Padding(
            padding: EdgeInsets.only(top: 25, bottom: 20),
            child: Center(
              child: Text(
                _userName,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Divider(),
          ),
          _buildProfileOption(
            icon: Icons.person,
            label: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserSubProfile()),
              );
            },
          ),
          Divider(),
          _buildProfileOption(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserSetting()),
              );
            },
          ),
          Divider(),
          _buildProfileOption(
            icon: Icons.info,
            label: 'About Us',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserAboutus()),
              );
            },
          ),
          Divider(),
          _buildProfileOption(
            icon: Icons.logout,
            label: 'Log Out',
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black),
              SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.black),
        ],
      ),
    );
  }
}