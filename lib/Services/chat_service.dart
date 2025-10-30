import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/chatmodel.dart';
import '../models/messagemodel.dart';

// Helper function to create a canonical chat ID
String getCanonicalChatId(String id1, String id2) {
  final ids = [id1, id2]..sort();
  return '${ids[0]}_${ids[1]}';
}

// Message status enum
enum MessageStatus { sent, delivered, read }

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String chatCollection = 'chats';

  // Firestore references
  final CollectionReference<Map<String, dynamic>> _chatsRef;
  final CollectionReference<Map<String, dynamic>> _usersRef;

  ChatService()
    : _chatsRef = FirebaseFirestore.instance.collection('chats'),
      _usersRef = FirebaseFirestore.instance.collection('users');

  // Extended ChatModel with additional fields for real-time features
  Map<String, dynamic> _enhanceChatData(
    ChatModel chat,
    Map<String, dynamic> data,
  ) {
    return {
      ...data,
      'participants': [chat.clientId, chat.providerId],
      'typing': {},
      'lastSeen': {},
      'unreadCount': {chat.clientId: 0, chat.providerId: 0},
    };
  }

  // Create a new chat if it doesn't exist
  Future<void> createChat({
    required String clientId,
    required String providerId,
    required DocumentReference clientRef,
    required DocumentReference providerRef,
  }) async {
    final chatId = getCanonicalChatId(clientId, providerId);
    final docRef = _chatsRef.doc(chatId);
    final doc = await docRef.get();

    if (!doc.exists) {
      ChatModel chat = ChatModel(
        chatId: chatId,
        clientId: clientId,
        providerId: providerId,
        lastMessage: '',
        lastMessageTime: Timestamp.now(),
        clientRef: clientRef,
        providerRef: providerRef,
      );

      // Store enhanced chat data with additional fields
      await docRef.set(_enhanceChatData(chat, chat.toMap()));
    }
  }

  // Send message with transaction and delivery status
  Future<void> sendMessage(String chatId, MessageModel message) async {
    final chatDocRef = _chatsRef.doc(chatId);
    final messagesRef = chatDocRef.collection('messages');

    // Prepare message with initial status
    final messageMap = message.toMap();
    final enhancedMessage = {
      ...messageMap,
      'status': MessageStatus.sent.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final msgDoc = messagesRef.doc();
    enhancedMessage['id'] = msgDoc.id;

    // Run transaction for atomicity
    await _firestore.runTransaction((transaction) async {
      // Add message to subcollection
      transaction.set(msgDoc, enhancedMessage);

      // Update chat with last message and increment unread count
      final otherUserId = getOtherUserId(chatId, message.senderId);
      transaction.update(chatDocRef, {
        'lastMessage': message.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': message.senderId,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    });

    // Send push notification (non-blocking)
    _sendPushNotification(chatId, message).catchError((e) {
      print('Push notification failed: $e');
    });
  }

  // Get user chats with pagination
  Stream<List<ChatModel>> getUserChatsStream(String userId, {int limit = 20}) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromDoc(doc)).toList(),
        );
  }

  // Load more chats for pagination
  Future<List<ChatModel>> loadMoreChats(
    String userId, {
    required ChatModel lastChat,
    int limit = 10,
  }) async {
    final snapshot =
        await _chatsRef
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageTime', descending: true)
            .startAfter([lastChat.lastMessageTime])
            .limit(limit)
            .get();

    return snapshot.docs.map((doc) => ChatModel.fromDoc(doc)).toList();
  }

  // Listen to messages with pagination and read receipts
  Stream<List<MessageModel>> listenMessages(
    String chatId, {
    int limit = 50,
    String? currentUserId,
  }) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
          final messages =
              snapshot.docs
                  .map(
                    (doc) => MessageModel.fromDoc(doc),
                  ) // Use fromDoc instead of fromMap
                  .toList();

          // Mark messages as read when viewing
          if (currentUserId != null) {
            await _markMessagesAsRead(chatId, currentUserId, messages);
          }

          return messages.reversed.toList(); // Return in chronological order
        });
  }

  // Load more messages for pagination
  Future<List<MessageModel>> loadMoreMessages(
    String chatId, {
    required MessageModel lastMessage,
    int limit = 25,
  }) async {
    final snapshot =
        await _chatsRef
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .startAfter([lastMessage.timestamp])
            .limit(limit)
            .get();

    return snapshot.docs
        .map(
          (doc) => MessageModel.fromDoc(doc),
        ) // Use fromDoc instead of fromMap
        .toList()
        .reversed
        .toList();
  }

  // Update message status (sent -> delivered -> read)
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    await _chatsRef.doc(chatId).collection('messages').doc(messageId).update({
      'status': status.toString().split('.').last,
      'statusTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead(
    String chatId,
    String userId,
    List<MessageModel> messages,
  ) async {
    // Get message status from the data map since status might not be a field in MessageModel
    final unreadMessages =
        messages.where((msg) {
          final messageData = msg.toMap();
          final status = messageData['status'] as String?;
          return msg.senderId != userId &&
              (status == null ||
                  status == MessageStatus.sent.toString().split('.').last ||
                  status == MessageStatus.delivered.toString().split('.').last);
        }).toList();

    if (unreadMessages.isNotEmpty) {
      final batch = _firestore.batch();

      for (final message in unreadMessages) {
        final messageRef = _chatsRef
            .doc(chatId)
            .collection('messages')
            .doc(message.id);
        batch.update(messageRef, {
          'status': MessageStatus.read.toString().split('.').last,
          'statusTimestamp': FieldValue.serverTimestamp(),
        });
      }

      // Reset unread count for this user
      final chatRef = _chatsRef.doc(chatId);
      batch.update(chatRef, {'unreadCount.$userId': 0});

      await batch.commit();
    }
  }

  // Typing indicators
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    await _chatsRef.doc(chatId).update({
      'typing.$userId': isTyping,
      'typingTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get typing status stream
  Stream<Map<String, dynamic>> getTypingStatus(String chatId) {
    return _chatsRef.doc(chatId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return {
        'typing': data?['typing'] ?? {},
        'typingTimestamp': data?['typingTimestamp'],
      };
    });
  }

  // Update user's last seen
  Future<void> updateLastSeen(String chatId, String userId) async {
    await _chatsRef.doc(chatId).update({
      'lastSeen.$userId': FieldValue.serverTimestamp(),
    });
  }

  // Get last seen information
  Stream<Map<String, dynamic>> getLastSeen(String chatId) {
    return _chatsRef.doc(chatId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data?['lastSeen'] ?? {};
    });
  }

  // Delete chat (soft delete)
  Future<void> deleteChat(String chatId, String userId) async {
    await _chatsRef.doc(chatId).update({
      'deletedBy': FieldValue.arrayUnion([userId]),
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete message (soft delete)
  Future<void> deleteMessage(
    String chatId,
    String messageId,
    String userId,
  ) async {
    await _chatsRef.doc(chatId).collection('messages').doc(messageId).update({
      'deleted': true,
      'deletedBy': userId,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // Clear chat history for user
  Future<void> clearChatHistory(String chatId, String userId) async {
    final batch = _firestore.batch();
    final messagesSnapshot =
        await _chatsRef
            .doc(chatId)
            .collection('messages')
            .where('timestamp', isLessThan: Timestamp.now())
            .get();

    for (final doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'clearedBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();
  }

  // FCM push notifications - Fixed version
  Future<void> _sendPushNotification(
    String chatId,
    MessageModel message,
  ) async {
    try {
      // In a real app, you would send this through your backend server
      // This is a placeholder for the notification logic
      print(
        'Sending push notification for chat: $chatId, message: ${message.text}',
      );

      // You would typically:
      // 1. Get the recipient's FCM token from your users collection
      // 2. Send a request to FCM servers via your backend
      // 3. Handle the response

      // Example of getting FCM token (you would store this when users log in)
      // String? fcmToken = await _messaging.getToken();

      // For now, we'll just log the notification intent
      final receiverId = getOtherUserId(chatId, message.senderId);
      print('Would send notification to user: $receiverId');
    } catch (e) {
      print('Error in push notification: $e');
      // Don't throw error - notification failure shouldn't break message sending
    }
  }

  // Helper methods
  String getOtherUserId(String chatId, String currentUserId) {
    final ids = chatId.split('_');
    return ids[0] == currentUserId ? ids[1] : ids[0];
  }

  // Get unread messages count
  Stream<int> getUnreadCount(String chatId, String userId) {
    return _chatsRef.doc(chatId).snapshots().map((snapshot) {
      final data = snapshot.data();
      final unreadCount = data?['unreadCount'] ?? {};
      return (unreadCount[userId] as num?)?.toInt() ?? 0;
    });
  }

  // Get total unread count across all chats
  Stream<int> getTotalUnreadCount(String userId) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final unreadCount = data['unreadCount'] ?? {};
            total += (unreadCount[userId] as num?)?.toInt() ?? 0;
          }
          return total;
        });
  }

  // Error handling wrapper
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      print(
        'Firestore error${context != null ? ' in $context' : ''}: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('Unexpected error${context != null ? ' in $context' : ''}: $e');
      rethrow;
    }
  }

  // Debug method to log chat state
  Future<void> debugChatState(String chatId) async {
    try {
      final chatDoc = await _chatsRef.doc(chatId).get();
      final messages =
          await _chatsRef
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();

      print('=== Chat Debug: $chatId ===');
      print('Chat exists: ${chatDoc.exists}');
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        print('Participants: ${data['participants']}');
        print('Unread counts: ${data['unreadCount']}');
        print('Last message: ${data['lastMessage']}');
      }
      print('Last 5 messages: ${messages.docs.length}');

      for (final doc in messages.docs) {
        final msg = doc.data();
        print(' - ${msg['text']} (${msg['status'] ?? 'no status'})');
      }
      print('=== End Debug ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }
}
