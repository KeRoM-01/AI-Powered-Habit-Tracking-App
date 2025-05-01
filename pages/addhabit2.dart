// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_habit_tracking_app/services/firestore.dart';

class AddHabitDetailsPage extends StatefulWidget {
  final String habit;
  final String category;
  final String? userId;

  const AddHabitDetailsPage({
    required this.habit,
    required this.category,
    this.userId,
  });

  @override
  _AddHabitDetailsPageState createState() => _AddHabitDetailsPageState();
}

class _AddHabitDetailsPageState extends State<AddHabitDetailsPage> {
  DateTime? _startDate;
  bool _morningReminder = false;
  bool _eveningReminder = false;
  bool _nightReminder = false;
  final TextEditingController _descriptionController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveHabitDetails() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a start date')),
      );
      return;
    }
    await _firestoreService.addHabit(
      widget.habit,
      widget.category,
      _startDate!,
      _morningReminder,
      _eveningReminder,
      _nightReminder,
      _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 99, 71, 224),
        title: Text('Set Habit Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit: ${widget.habit}',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Category: ${widget.category}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter habit description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Date: ${_startDate != null ? DateFormat.yMMMd().format(_startDate!) : 'Not set'}',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: Text('Select Start Date'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminders:',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    title: Text('Morning'),
                    value: _morningReminder,
                    onChanged: (bool? value) {
                      setState(() {
                        _morningReminder = value!;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  CheckboxListTile(
                    title: Text('Evening'),
                    value: _eveningReminder,
                    onChanged: (bool? value) {
                      setState(() {
                        _eveningReminder = value!;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  CheckboxListTile(
                    title: Text('Night'),
                    value: _nightReminder,
                    onChanged: (bool? value) {
                      setState(() {
                        _nightReminder = value!;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _saveHabitDetails();
                  Navigator.pop(context, {
                    'habit': widget.habit,
                    'category': widget.category,
                    'startDate': _startDate,
                    'morningReminder': _morningReminder,
                    'eveningReminder': _eveningReminder,
                    'nightReminder': _nightReminder,
                    'description': _descriptionController.text,
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}