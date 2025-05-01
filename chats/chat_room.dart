class ChatRoom {
  final String id;
  final String name;

  ChatRoom({required this.id, required this.name});

  factory ChatRoom.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatRoom(
      id: id,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
    };
  }
}