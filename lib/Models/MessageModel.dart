import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  String? id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final String type;
  final bool isRead;

  MessageModel({
    this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'type': type,
      'isRead': isRead,
    };
  }

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] as Timestamp,
      type: data['type'] ?? 'text',
      isRead: data['isRead'] ?? false,
    );
  }
}
