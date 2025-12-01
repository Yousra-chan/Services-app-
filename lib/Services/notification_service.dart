// services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Remove conflicting imports
import 'package:myapp/services/firebase_service.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';

// Navigation service for handling notification navigation
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> navigateToDiscussion(String chatId, String userId) async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final participants = List<String>.from(chatData['participants'] ?? []);
        final participantNames =
            Map<String, String>.from(chatData['participantNames'] ?? {});

        // Get the other participant's name
        final otherUserId =
            participants.firstWhere((id) => id != userId, orElse: () => '');
        final contactName = participantNames[otherUserId] ?? 'Unknown User';

        // Navigate directly to DiscussionPage WITH CUSTOM ROUTE
        navigatorKey.currentState?.push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ChangeNotifierProvider(
              create: (context) => ChatViewModel(userId: userId),
              child: DiscussionPage(
                contactName: contactName,
                isOnline: true,
                chatId: chatId,
                currentUserId: userId,
                chatViewModel: ChatViewModel(userId: userId),
              ),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navigating to discussion: $e');
    }
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    print('🔔 [NotificationService] Initializing notification service...');

    await _requestPermissions();
    await _initializeLocalNotifications();
    await _configureFCM();
    _setupForegroundMessageHandler();

    print('✅ [NotificationService] Notification service initialized');
  }

  static Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [NotificationService] User granted notification permission');
      } else {
        print('❌ [NotificationService] User declined notification permission');
      }

      await Permission.notification.request();
    } catch (e) {
      print('❌ [NotificationService] Error requesting permissions: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (id, title, body, payload) async {},
      );

      final InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings);
      print('✅ [NotificationService] Local notifications initialized');
    } catch (e) {
      print(
          '❌ [NotificationService] Error initializing local notifications: $e');
    }
  }

  static Future<void> _configureFCM() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('🔔 [NotificationService] FCM Token: $token');

      _saveTokenToFirestore(token);

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔔 [NotificationService] FCM Token refreshed: $newToken');
        _saveTokenToFirestore(newToken);
      });

      print('✅ [NotificationService] FCM configured');
    } catch (e) {
      print('❌ [NotificationService] Error configuring FCM: $e');
    }
  }

  static void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          '🔔 [NotificationService] Received message in foreground: ${message.notification?.title}');

      showNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        payload: message.data['chatId'] ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          '🔔 [NotificationService] App opened from background via notification');
      _handleNotificationClick(message.data);
    });
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'main_channel',
        'Main Notifications',
        channelDescription: 'Main notification channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
      print('✅ [NotificationService] Local notification shown: $title');
    } catch (e) {
      print('❌ [NotificationService] Error showing local notification: $e');
    }
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'];
      final notificationType = data['type'];

      if (chatId != null && notificationType == 'message') {
        _navigateToDiscussion(chatId);
      }
    } catch (e) {
      print('❌ [NotificationService] Error handling notification click: $e');
    }
  }

  static void _navigateToDiscussion(String chatId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId != null) {
        NavigationService.navigateToDiscussion(chatId, userId);
      }
    } catch (e) {
      print('❌ [NotificationService] Error navigating to discussion: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final userId = await _getCurrentUserId();
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [NotificationService] FCM token saved to Firestore');
    } catch (e) {
      print('❌ [NotificationService] Error saving FCM token: $e');
    }
  }

  static Future<String?> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ [NotificationService] Subscribed to topic: $topic');
    } catch (e) {
      print('❌ [NotificationService] Error subscribing to topic: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ [NotificationService] Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ [NotificationService] Error unsubscribing from topic: $e');
    }
  }

  static Future<void> handleInitialMessage() async {
    try {
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage.data);
      }
    } catch (e) {
      print('❌ [NotificationService] Error handling initial message: $e');
    }
  }

  // FIXED: SINGLE createMessageNotification method (removed duplicate)
  static Future<void> createMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    required String senderId,
  }) async {
    try {
      print(
          '🔔 [NotificationService] Creating message notification for: $receiverId');

      // Use FirebaseService instead of direct Firestore for consistency
      await FirebaseService.createNotification(
        userId: receiverId,
        title: 'New message from $senderName',
        message: messageText.length > 50
            ? '${messageText.substring(0, 50)}...'
            : messageText,
        type: 'message',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        actionText: 'View Chat',
      );

      print(
          '✅ [NotificationService] Message notification created for user: $receiverId');
    } catch (e) {
      print('❌ [NotificationService] Error creating message notification: $e');

      // Fallback: Try direct Firestore if FirebaseService fails
      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': receiverId,
          'title': 'New message from $senderName',
          'message': messageText.length > 50
              ? '${messageText.substring(0, 50)}...'
              : messageText,
          'time': Timestamp.now(),
          'isRead': false,
          'type': 'message',
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'actionText': 'View Chat',
        });
        print('✅ [NotificationService] Fallback notification created');
      } catch (fallbackError) {
        print('❌ [NotificationService] Fallback also failed: $fallbackError');
      }
    }
  }

  // ADD: Test notification method
  static Future<void> createTestNotification(String userId) async {
    try {
      print('🔔 [NotificationService] Creating test notification...');

      await FirebaseService.createNotification(
        userId: userId,
        title: 'Test Notification 🔔',
        message:
            'This is a test notification to verify the notification system is working correctly',
        type: 'message',
        chatId: 'test_chat_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'test_sender_123',
        senderName: 'Test System',
        actionText: 'View Test',
      );

      print('✅ [NotificationService] Test notification created successfully');
    } catch (e) {
      print('❌ [NotificationService] Error creating test notification: $e');
    }
  }

  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      await Firebase.initializeApp();
      await showNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        payload: message.data['chatId'] ?? '',
      );
      print('✅ [NotificationService] Background notification handled');
    } catch (e) {
      print('❌ [NotificationService] Error in background handler: $e');
    }
  }
}
