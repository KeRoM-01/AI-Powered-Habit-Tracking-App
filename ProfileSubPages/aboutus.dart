// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserAboutus extends StatefulWidget {
  @override
  State<UserAboutus> createState() => _UserAboutusState();
}

class _UserAboutusState extends State<UserAboutus> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 99, 71, 224),
        title: Text('About Us',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'AI Powered Habit Tracking App',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Developer: Kerollos Magdy Lamey',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Contact Email: kerollosmagdy31@gmail.com',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Follow us on social media:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.facebook),
                  onPressed: () {
                    // Handle Facebook button press
                  },
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.twitter),
                  onPressed: () {
                    // Handle Twitter button press
                  },
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.instagram),
                  onPressed: () {
                    // Handle Instagram button press
                  },
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.linkedin),
                  onPressed: () {
                    // Handle LinkedIn button press
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}