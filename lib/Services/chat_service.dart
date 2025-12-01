import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ChatModel.dart';
import '../models/MessageModel.dart';
import 'firebase_service.dart';

String getCanonicalChatId(String id1, String id2) {
  final ids = [id1, id2]..sort();
  return '${ids[0]}_${ids[1]}';
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference<Map<String, dynamic>> _chatsRef;
  final CollectionReference<Map<String, dynamic>> _usersRef;

  ChatService()
      : _chatsRef = FirebaseFirestore.instance.collection('chats'),
        _usersRef = FirebaseFirestore.instance.collection('users');

  // === CRÉATION ET RÉCUPÉRATION DES CHATS ===

// In chat_service.dart - Update createChat method to prevent self-chats
  Future<String?> createChat({
    required String clientId,
    required String providerId,
  }) async {
    try {
      // Prevent self-chatting
      if (clientId == providerId) {
        throw Exception(
            'Vous ne pouvez pas créer une discussion avec vous-même');
      }

      final chatId = getCanonicalChatId(clientId, providerId);
      final docRef = _chatsRef.doc(chatId);
      final existingChat = await docRef.get();

      if (existingChat.exists) {
        return chatId;
      }

      final clientDoc = await _usersRef.doc(clientId).get();
      final providerDoc = await _usersRef.doc(providerId).get();

      if (!clientDoc.exists || !providerDoc.exists) {
        throw Exception('Un des utilisateurs n\'existe pas');
      }

      final clientData = clientDoc.data()!;
      final providerData = providerDoc.data()!;

      final chatData = {
        'chatId': chatId,
        'clientId': clientId,
        'providerId': providerId,
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
        'participants': [clientId, providerId],
        'participantNames': {
          clientId: clientData['name'] ?? 'Client',
          providerId: providerData['name'] ?? 'Prestataire'
        },
        'participantRoles': {
          clientId: clientData['role'] ?? 'client',
          providerId: providerData['role'] ?? 'provider'
        },
        'unreadCount': {clientId: 0, providerId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(chatData);

      await _usersRef.doc(clientId).update({
        'chatIds': FieldValue.arrayUnion([chatId]),
      });
      await _usersRef.doc(providerId).update({
        'chatIds': FieldValue.arrayUnion([chatId]),
      });

      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId, {int limit = 20}) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromDoc(doc)).toList();
    });
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _chatsRef.doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromDoc(doc);
      }
      return null;
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }

  // === GESTION DES MESSAGES ===

// In chat_service.dart - Update sendMessage method
  Future<void> sendMessage(String chatId, MessageModel message) async {
    final chatDocRef = _chatsRef.doc(chatId);
    final messagesRef = chatDocRef.collection('messages');

    final chatDoc = await chatDocRef.get();
    if (!chatDoc.exists) {
      throw Exception('Le chat n\'existe pas');
    }

    final participants =
        List<String>.from(chatDoc.data()?['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != message.senderId);

    // Get participant names for notification
    final participantNames = chatDoc.data()?['participantNames'] ?? {};
    final senderName = participantNames[message.senderId] ?? 'Someone';
    final receiverName = participantNames[otherUserId] ?? 'User';

    final messageDoc = messagesRef.doc();
    final messageData = {
      ...message.toMap(),
      'id': messageDoc.id,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageDoc, messageData);
      transaction.update(chatDocRef, {
        'lastMessage': message.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': message.senderId,
        'lastMessageType': message.type,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    });

    // ✅ ADD THIS: Create notification for the receiver
    try {
      await FirebaseService.createNotification(
        userId: otherUserId,
        title: 'New Message from $senderName',
        message: message.text.length > 50
            ? '${message.text.substring(0, 50)}...'
            : message.text,
        type: 'message',
        chatId: chatId,
        senderId: message.senderId,
        senderName: senderName,
        actionText: 'Reply',
      );
      print('📬 Notification created for user: $otherUserId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }

    print('Message envoyé avec succès dans le chat $chatId');
  }

  Future<void> testNotification(String chatId, String currentUserId) async {
    try {
      final testMessage = MessageModel(
        senderId: currentUserId,
        text: 'Test message for notification',
        timestamp: Timestamp.now(),
        type: 'text',
      );

      await sendMessage(chatId, testMessage);
      print('✅ Test message and notification sent');
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }

  Stream<List<MessageModel>> listenMessages(
    String chatId, {
    int limit = 50,
    String? currentUserId,
  }) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromMap({...data, 'id': doc.id});
      }).toList();

      if (currentUserId != null && messages.isNotEmpty) {
        _markMessagesAsRead(chatId, currentUserId, messages);
      }

      return messages;
    });
  }

  Future<void> _markMessagesAsRead(
    String chatId,
    String userId,
    List<MessageModel> messages,
  ) async {
    try {
      final unreadMessages = messages
          .where((msg) => msg.senderId != userId && !msg.isRead)
          .toList();

      if (unreadMessages.isNotEmpty) {
        final batch = _firestore.batch();
        final chatRef = _chatsRef.doc(chatId);

        for (final message in unreadMessages) {
          if (message.id != null) {
            final messageRef =
                _chatsRef.doc(chatId).collection('messages').doc(message.id!);
            batch.update(messageRef, {'isRead': true});
          }
        }

        batch.update(chatRef, {'unreadCount.$userId': 0});
        await batch.commit();
        print('${unreadMessages.length} messages marqués comme lus');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // === COMPTEURS ET STATUTS ===

  Stream<int> getUnreadCount(String chatId, String userId) {
    return _chatsRef.doc(chatId).snapshots().map((snapshot) {
      final data = snapshot.data();
      final unreadCount = data?['unreadCount'] ?? {};
      final count = unreadCount[userId];
      if (count is int) return count;
      if (count is num) return count.toInt();
      return 0;
    });
  }

  Stream<int> getTotalUnreadCount(String userId) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final unreadCount = doc.data()['unreadCount'] ?? {};
        final count = unreadCount[userId];
        if (count is int) total += count;
        if (count is num) total += count.toInt();
      }
      return total;
    });
  }

  // In chat_service.dart - Update getAvailableProviders method
  Future<List<Map<String, dynamic>>> getAvailableProviders() async {
    try {
      print('🔍 Fetching available providers...');

      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // First try to get users with provider role
      final providerQuery =
          await _usersRef.where('role', isEqualTo: 'provider').limit(20).get();

      print('📊 Found ${providerQuery.docs.length} providers with role filter');

      // Filter out current user and map to list
      final providers = providerQuery.docs
          .where((doc) => doc.id != currentUserId) // Exclude current user
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Provider',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'] ?? '',
          'role': data['role'] ?? 'provider',
        };
      }).toList();

      if (providers.isNotEmpty) {
        return providers;
      }

      // If no providers found, get all users and exclude current user
      print('🔄 No providers found with role, fetching all users...');
      final allUsers = await _usersRef.limit(20).get();

      final potentialProviders = allUsers.docs
          .where((doc) => doc.id != currentUserId) // Exclude current user
          .where((doc) {
        final data = doc.data();
        return data['name']?.isNotEmpty == true ||
            data['email']?.isNotEmpty == true;
      }).map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'User ${doc.id.substring(0, 6)}',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'] ?? '',
          'role': data['role'] ?? 'user',
        };
      }).toList();

      print(
          '👥 Found ${potentialProviders.length} potential providers (excluding self)');
      return potentialProviders;
    } catch (e) {
      print('❌ Error getting providers: $e');
      return [];
    }
  }

  // Alternative si pas de champ 'role'
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await _usersRef.limit(10).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Utilisateur',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'] ?? '',
          'role': data['role'] ?? 'user',
        };
      }).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // === SUPPRESSION ===

  Future<void> deleteChat(String chatId, String userId) async {
    try {
      await _chatsRef.doc(chatId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });

      await _usersRef.doc(userId).update({
        'chatIds': FieldValue.arrayRemove([chatId]),
      });

      print('Chat $chatId supprimé pour l\'utilisateur $userId');
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}
