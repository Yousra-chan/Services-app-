import 'package:cloud_firestore/cloud_firestore.dart';
// import 'messagemodel.dart'; // Uncomment if you use the messages list in the model

class ChatModel {
  final String chatId; // Firestore document ID (required in constructor)
  final String clientId;
  final String providerId;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final DocumentReference clientRef;
  final DocumentReference providerRef;
  // final List<MessageModel>? messages; // Added back if desired

  ChatModel({
    required this.chatId,
    required this.clientId,
    required this.providerId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.clientRef,
    required this.providerRef,

    // this.messages, // If messages is included
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'providerId': providerId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'clientRef': clientRef,
      'providerRef': providerRef,
      // 'chatId' is not stored inside the document, only used as the doc ID
    };
  }

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      chatId: doc.id,
      clientId: data['clientId'] ?? '',

      providerId: data['providerId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] as Timestamp,
      clientRef: data['clientRef'] as DocumentReference,
      providerRef: data['providerRef'] as DocumentReference,
    );
  }
}
