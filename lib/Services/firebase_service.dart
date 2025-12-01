// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:myapp/models/service_provider.dart';
import 'package:myapp/models/notification_item.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Fetch categories from Firestore
  static Stream<List<CategoryModel>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .handleError((error) {
      print('❌ Error fetching categories: $error');
      return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
    }).map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  // Alternative search method if arrayContains doesn't work
  static Stream<List<ServiceProvider>> searchProvidersAlternative(
      String query) {
    if (query.isEmpty) {
      return getAllProviders();
    }

    return _firestore
        .collection('providers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final providers = snapshot.docs
          .map((doc) => ServiceProvider.fromFirestore(doc))
          .toList();

      // Filter locally by name or category
      return providers.where((provider) {
        final nameMatch =
            provider.name.toLowerCase().contains(query.toLowerCase());
        final categoryMatch =
            provider.category.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch =
            provider.description.toLowerCase().contains(query.toLowerCase());

        return nameMatch || categoryMatch || descriptionMatch;
      }).toList();
    });
  }

  static Stream<List<ServiceProvider>> getAllProviders() {
    return _firestore
        .collection('providers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .handleError((error) {
      print('❌ Error fetching all providers: $error');
      return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
    }).map((snapshot) => snapshot.docs
            .map((doc) => ServiceProvider.fromFirestore(doc))
            .toList());
  }

  // Fetch popular providers from Firestore
  static Stream<List<ServiceProvider>> getPopularProviders() {
    return _firestore
        .collection('providers')
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .handleError((error) {
      print('❌ Error fetching popular providers: $error');
      return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
    }).map((snapshot) => snapshot.docs
            .map((doc) => ServiceProvider.fromFirestore(doc))
            .toList());
  }

  // Search providers by name or category
  static Stream<List<ServiceProvider>> searchProviders(String query) {
    if (query.isEmpty) {
      return getPopularProviders();
    }

    return _firestore
        .collection('providers')
        .where('searchKeywords', arrayContains: query.toLowerCase())
        .snapshots()
        .handleError((error) {
      print('❌ Error searching providers: $error');
      return searchProvidersAlternative(query);
    }).map((snapshot) => snapshot.docs
            .map((doc) => ServiceProvider.fromFirestore(doc))
            .toList());
  }

  // Get user data
  static Stream<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  static Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Create a new notification (for non-message types)
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? chatId,
    String? senderId,
    String? senderName,
    String actionText = 'View',
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'title': title,
        'message': message,
        'time': Timestamp.now(),
        'lastMessageTime': Timestamp.now(),
        'isRead': false,
        'type': type,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'actionText': actionText,
        'messageCount': 1,
      };

      await _firestore.collection('notifications').add(notificationData);
      print('✅ Notification created for user: $userId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // Create or update message notification with grouping
  static Future<void> createOrUpdateMessageNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    try {
      print('🔔 [FirebaseService] Creating/updating message notification');
      print('🔔 [FirebaseService] User: $userId, Sender: $senderName');

      // Check if there's already an unread notification from this sender
      final existingNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('senderId', isEqualTo: senderId)
          .where('type', isEqualTo: 'message')
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();

      final now = Timestamp.now();
      final truncatedMessage = messageText.length > 50
          ? '${messageText.substring(0, 50)}...'
          : messageText;

      if (existingNotifications.docs.isNotEmpty) {
        // UPDATE EXISTING NOTIFICATION
        final existingDoc = existingNotifications.docs.first;
        final existingData = existingDoc.data();
        final currentCount =
            (existingData['messageCount'] as num?)?.toInt() ?? 1;

        await _firestore
            .collection('notifications')
            .doc(existingDoc.id)
            .update({
          'message': truncatedMessage,
          'lastMessageTime': now,
          'messageCount': currentCount + 1,
          'isRead': false,
          'chatId': chatId,
        });

        print(
            '✅ [FirebaseService] Updated existing notification: ${existingDoc.id}');
        print('✅ [FirebaseService] Message count: ${currentCount + 1}');
      } else {
        // CREATE NEW NOTIFICATION
        final notificationData = {
          'userId': userId,
          'title': 'New Message from $senderName',
          'message': truncatedMessage,
          'time': now,
          'lastMessageTime': now,
          'isRead': false,
          'type': 'message',
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'actionText': 'Reply',
          'messageCount': 1,
        };

        final docRef =
            await _firestore.collection('notifications').add(notificationData);
        print('✅ [FirebaseService] Created new notification: ${docRef.id}');
      }
    } catch (e) {
      print(
          '❌ [FirebaseService] Error in createOrUpdateMessageNotification: $e');
    }
  }

  static String _notificationTypeToString(HomeNotificationType type) {
    return type.toString().split('.').last;
  }

  // Get user notifications with proper grouping
  static Stream<List<HomeNotificationItem>> getUserNotifications(
      String userId) {
    print('🔔 [FirebaseService] Getting notifications for user: $userId');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .handleError((error) {
      print('❌ [FirebaseService] Error fetching notifications: $error');
      return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
    }).map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        try {
          return HomeNotificationItem.fromFirestore(doc);
        } catch (e) {
          print('❌ [FirebaseService] Error parsing notification ${doc.id}: $e');
          return HomeNotificationItem(
            id: doc.id,
            title: 'Error loading notification',
            message: 'Could not load this notification',
            type: HomeNotificationType.message,
            isRead: true,
            time: DateTime.now(),
            lastMessageTime: DateTime.now(),
          );
        }
      }).toList();

      print(
          '🔔 [FirebaseService] Successfully loaded ${notifications.length} notifications');
      return notifications;
    });
  }

  // Test method to verify everything works
  static Future<void> createTestNotification(String userId) async {
    try {
      print('🔔 [FirebaseService] Creating test notification...');
      await createNotification(
        userId: userId,
        title: 'Test Notification 🔔',
        message:
            'This is a test notification to verify everything works correctly',
        type: 'message',
        chatId: 'test_chat_123',
        senderId: 'test_sender_123',
        senderName: 'Test User',
        actionText: 'View Test',
      );
      print('✅ [FirebaseService] Test notification created successfully');
    } catch (e) {
      print('❌ [FirebaseService] Error creating test notification: $e');
    }
  }

  // Additional helper method to get categories as List (non-stream)
  static Future<List<CategoryModel>> getCategoriesList() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching categories list: $e');
      return CategoryModel.defaultCategories;
    }
  }

  // Mark all notifications from a specific sender as read
  static Future<void> markSenderNotificationsAsRead(
      String userId, String senderId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('senderId', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print(
          '✅ Marked ${notifications.docs.length} notifications from $senderId as read');
    } catch (e) {
      print('❌ Error marking sender notifications as read: $e');
    }
  }

  // Clear message count when user reads the chat
  static Future<void> resetMessageCount(String userId, String senderId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('senderId', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        await doc.reference.update({
          'messageCount': 1,
          'isRead': true,
        });
      }

      print('✅ Reset message count for notifications from $senderId');
    } catch (e) {
      print('❌ Error resetting message count: $e');
    }
  }

  // Add to your FirebaseService class
  static Stream<List<CategoryModel>> getSubCategories(String categoryId) {
    return FirebaseFirestore.instance
        .collection('categories')
        .where('parentId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }
}
