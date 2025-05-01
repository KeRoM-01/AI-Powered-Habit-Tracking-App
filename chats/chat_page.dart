// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String chatRoomName;

  const ChatPage({required this.chatRoomId, required this.chatRoomName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  String _userName = '';
  final String usersCollection = 'users'; // Define the users collection name

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(usersCollection).doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
        });
      }
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).collection('messages').add({
      'text': _controller.text.trim(),
      'time': DateTime.now(),
      'sender': _userName,
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Community of ${widget.chatRoomName}',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).collection('messages').orderBy('time', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var messages = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return Align(
                        alignment: message['sender'] == _userName ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5.0),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: message['sender'] == _userName ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            crossAxisAlignment: message['sender'] == _userName ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['sender'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                message['text'],
                                style: GoogleFonts.poppins(fontSize: 16.0),
                              ),
                              SizedBox(height: 5.0),
                              Text(
                                DateFormat('hh:mm a').format(message['time'].toDate()),
                                style: GoogleFonts.poppins(
                                  fontSize: 12.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue, size: 30.0),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}