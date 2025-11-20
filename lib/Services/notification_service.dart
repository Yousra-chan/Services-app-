// services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/screens/home/home_constants.dart'
    hide FirebaseService, NotificationType;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myapp/models/NotificationsModel.dart';

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

        // Navigate directly to DiscussionPage
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (context) => ChatViewModel(userId: userId),
              child: DiscussionPage(
                contactName: contactName,
                isOnline: true,
                chatId: chatId,
                currentUserId: userId,
                chatViewModel: ChatViewModel(userId: userId),
              ),
            ),
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
    print('🔔 Initializing notification service...');

    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM
    await _configureFCM();

    // Listen for messages when app is in foreground
    _setupForegroundMessageHandler();

    print('✅ Notification service initialized');
  }

  static Future<void> _requestPermissions() async {
    try {
      // Request notification permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else {
        print('❌ User declined notification permission');
      }

      // Also request for local notifications
      await Permission.notification.request();
    } catch (e) {
      print('❌ Error requesting permissions: $e');
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
      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  static Future<void> _configureFCM() async {
    try {
      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('🔔 FCM Token: $token');

      // Save this token to your user document in Firestore
      _saveTokenToFirestore(token);

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔔 FCM Token refreshed: $newToken');
        _saveTokenToFirestore(newToken);
      });

      print('✅ FCM configured');
    } catch (e) {
      print('❌ Error configuring FCM: $e');
    }
  }

  static void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          '🔔 Received message in foreground: ${message.notification?.title}');

      // Show local notification when app is in foreground
      showNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        payload: message.data['chatId'] ?? '',
      );
    });

    // Handle when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened from background via notification');
      _handleNotificationClick(message.data);
    });
  }

  // PUBLIC method to show notifications
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
      print('✅ Local notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
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
      print('❌ Error handling notification click: $e');
    }
  }

  static void _navigateToDiscussion(String chatId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId != null) {
        NavigationService.navigateToDiscussion(chatId, userId);
      }
    } catch (e) {
      print('❌ Error navigating to discussion: $e');
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
      print('✅ FCM token saved to Firestore');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  static Future<String?> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // Subscribe to topics (optional)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  // Get initial message when app is launched from terminated state
  static Future<void> handleInitialMessage() async {
    try {
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage.data);
      }
    } catch (e) {
      print('❌ Error handling initial message: $e');
    }
  }

  // Create message notification
  static Future<void> createMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    required String senderId,
  }) async {
    try {
      await FirebaseService.createNotification(
        userId: receiverId,
        title: 'New message from $senderName',
        message: messageText.length > 50
            ? '${messageText.substring(0, 50)}...'
            : messageText,
        type: NotificationType.message,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        actionText: 'View Chat',
      );
      print('✅ Message notification created for user: $receiverId');
    } catch (e) {
      print('❌ Error creating message notification: $e');
    }
  }

  // Background message handler (called from main.dart)
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
      print('✅ Background notification handled');
    } catch (e) {
      print('❌ Error in background handler: $e');
    }
  }
}
