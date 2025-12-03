import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Your existing services
import 'package:myapp/services/firebase_service.dart';

// ============================================================================
// NAVIGATION SERVICE
// ============================================================================

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> navigateToDiscussion(String chatId, String userId) async {
    try {
      if (navigatorKey.currentState == null) {
        print('❌ Navigator not ready');
        return;
      }

      // Get chat details from Firestore
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        print('❌ Chat not found: $chatId');
        return;
      }

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final participantNames =
          Map<String, String>.from(chatData['participantNames'] ?? {});

      // Get the other participant's name
      final otherUserId =
          participants.firstWhere((id) => id != userId, orElse: () => '');
      final contactName = participantNames[otherUserId] ?? 'Unknown User';

      print('📍 Navigating to chat: $contactName (ID: $chatId)');

      // Navigate using MaterialPageRoute
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) {
            // Import your actual DiscussionPage here
            return Scaffold(
              appBar: AppBar(
                title: Text('Chat with $contactName'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chat ID: $chatId'),
                    Text('Contact: $contactName'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => navigatorKey.currentState!.pop(),
                      child: Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('❌ Error navigating to discussion: $e');
    }
  }

  static Future<void> navigateToOrder(String orderId) async {
    try {
      navigatorKey.currentState!.pushNamed(
        '/order/$orderId',
      );
    } catch (e) {
      print('❌ Error navigating to order: $e');
    }
  }
}

// ============================================================================
// NOTIFICATION SERVICE - ALL STATIC VERSION
// ============================================================================

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Static instances
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Static state variables
  static String? _currentFCMToken;
  static String? _currentUserId;
  static bool _isInitialized = false;
  static int _badgeCount = 0;

  // Static stream controllers
  static final StreamController<Map<String, dynamic>>
      _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<int> _badgeCountStreamController =
      StreamController<int>.broadcast();

  // Static getters
  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;
  static Stream<int> get badgeCountStream => _badgeCountStreamController.stream;
  static String? get currentFCMToken => _currentFCMToken;
  static bool get isInitialized => _isInitialized;
  static int get badgeCount => _badgeCount;

  // ============================================================================
  // INITIALIZATION & SETUP (STATIC)
  // ============================================================================

  static Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ NotificationService already initialized');
      return;
    }

    print('🔔 [NotificationService] Initializing...');

    try {
      // 1. Request permissions
      await _requestPermissions();

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Configure Firebase Cloud Messaging
      await _configureFCM();

      // 4. Set up message handlers
      _setupMessageHandlers();

      // 5. Set up auth listener
      _setupAuthListener();

      // 6. Set background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      print('✅ [NotificationService] Initialized successfully');
    } catch (e) {
      print('❌ [NotificationService] Initialization failed: $e');
      rethrow;
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          '📱 [NotificationService] FCM Permission: ${settings.authorizationStatus}');

      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      print('❌ [NotificationService] Error requesting permissions: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (id, title, body, payload) async {
          print('📱 Local notification received on iOS');
        },
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _onNotificationTapped(response.payload);
        },
        onDidReceiveBackgroundNotificationResponse:
            (NotificationResponse response) {
          _onNotificationTapped(response.payload);
        },
      );

      print('✅ [NotificationService] Local notifications initialized');
    } catch (e) {
      print(
          '❌ [NotificationService] Error initializing local notifications: $e');
    }
  }

  static Future<void> _configureFCM() async {
    try {
      // Get current FCM token
      _currentFCMToken = await _firebaseMessaging.getToken();
      print('🔑 [NotificationService] FCM Token: $_currentFCMToken');

      // Save token to Firestore
      await _saveTokenToFirestore(_currentFCMToken);

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 [NotificationService] FCM Token refreshed: $newToken');
        _currentFCMToken = newToken;
        _saveTokenToFirestore(newToken);
      });

      // Get initial notification
      await _handleInitialNotification();

      // Set notification settings
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      print('✅ [NotificationService] FCM configured');
    } catch (e) {
      print('❌ [NotificationService] Error configuring FCM: $e');
    }
  }

  static void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUserId = user.uid;
        print('👤 [NotificationService] User authenticated: ${user.uid}');

        if (_currentFCMToken != null) {
          _saveTokenToFirestore(_currentFCMToken);
        }

        _subscribeToUserTopics(user.uid);
      } else {
        _currentUserId = null;
        print('👤 [NotificationService] User signed out');
        _unsubscribeFromAllTopics();
      }
    });
  }

  static void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 [NotificationService] Foreground message received');
      _handleIncomingMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 [NotificationService] App opened from background');
      _handleIncomingMessage(message);
      _handleNotificationNavigation(message.data);
    });
  }

  // ============================================================================
  // MESSAGE HANDLING (STATIC)
  // ============================================================================

  static Future<void> _handleIncomingMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final notification = message.notification;

      print('📨 [NotificationService] Message data: $data');

      // Update badge count
      _updateBadgeCount(1);

      // Add to notification stream
      _notificationStreamController.add({
        'id': message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': notification?.title ?? data['title'] ?? 'New Notification',
        'body': notification?.body ?? data['body'] ?? '',
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': data['type'] ?? 'general',
      });

      // Show local notification
      final shouldShowNotification = data['show_notification'] != 'false';
      if (shouldShowNotification) {
        await _showLocalNotification(
          title: notification?.title ?? data['title'] ?? 'New Notification',
          body: notification?.body ?? data['body'] ?? '',
          payload: json.encode(data),
          notificationType: data['type'] ?? 'general',
        );
      }

      // Update Firestore notification if needed
      if (data['type'] == 'message' && _currentUserId != null) {
        await _updateFirestoreNotification(data);
      }
    } catch (e) {
      print('❌ [NotificationService] Error handling incoming message: $e');
    }
  }

  static Future<void> _updateFirestoreNotification(
      Map<String, dynamic> data) async {
    try {
      final chatId = data['chatId'];
      final senderId = data['senderId'];
      final senderName = data['senderName'] ?? 'Someone';
      final messageText = data['message'] ?? 'New message';

      if (chatId != null && senderId != null && _currentUserId != null) {
        await FirebaseService.createOrUpdateMessageNotification(
          userId: _currentUserId!,
          senderId: senderId,
          senderName: senderName,
          messageText: messageText,
          chatId: chatId,
        );
      }
    } catch (e) {
      print(
          '❌ [NotificationService] Error updating Firestore notification: $e');
    }
  }

  static Future<void> _handleInitialNotification() async {
    try {
      final RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();

      if (initialMessage != null) {
        print(
            '📱 [NotificationService] App opened from terminated state via notification');
        await Future.delayed(Duration(seconds: 1));
        _handleNotificationNavigation(initialMessage.data);
      }
    } catch (e) {
      print('❌ [NotificationService] Error handling initial notification: $e');
    }
  }

  // ============================================================================
  // PUBLIC STATIC METHODS (for main.dart and chat_service.dart)
  // ============================================================================

  static Future<void> handleInitialMessage() async {
    try {
      print('📱 [NotificationService] Handling initial message...');

      final RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        print('📱 [NotificationService] App opened from terminated state');
        print('📱 Message data: ${initialMessage.data}');

        await Future.delayed(Duration(seconds: 2));
        _handleNotificationNavigation(initialMessage.data);
      } else {
        print('📱 [NotificationService] No initial message');
      }
    } catch (e) {
      print('❌ [NotificationService] Error handling initial message: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      print('📱 [NotificationService] Showing notification: $title');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Colors.red,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showWhen: true,
        autoCancel: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'akhdem-li-notifications',
      );

      final NotificationDetails details = NotificationDetails(
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

      print('✅ [NotificationService] Notification shown: $title');
    } catch (e) {
      print('❌ [NotificationService] Error showing notification: $e');
    }
  }

  static Future<void> createMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    required String senderId,
  }) async {
    try {
      print('📤 [NotificationService] Creating message notification');
      print('📤 Receiver: $receiverId');
      print('📤 Sender: $senderName ($senderId)');
      print('📤 Message: $messageText');
      print('📤 Chat ID: $chatId');

      // 1. Update grouped notification in Firestore
      await FirebaseService.createOrUpdateMessageNotification(
        userId: receiverId,
        senderId: senderId,
        senderName: senderName,
        messageText: messageText,
        chatId: chatId,
      );

      print('✅ [NotificationService] Firestore notification updated');

      // 2. Send push notification
      await _sendPushNotificationToUser(
        receiverId: receiverId,
        senderName: senderName,
        messageText: messageText,
        chatId: chatId,
        senderId: senderId,
      );

      print(
          '✅ [NotificationService] Message notification created successfully');
    } catch (e) {
      print('❌ [NotificationService] Error creating message notification: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS (STATIC)
  // ============================================================================

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    String notificationType = 'general',
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Colors.red,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showWhen: true,
        autoCancel: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'akhdem-li-notifications',
      );

      final NotificationDetails details = NotificationDetails(
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

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      final chatId = data['chatId'];
      final orderId = data['orderId'];

      print('📍 [NotificationService] Handling navigation for type: $type');

      if (type == 'message' && chatId != null && _currentUserId != null) {
        print('📍 Navigating to chat: $chatId');
        NavigationService.navigateToDiscussion(chatId, _currentUserId!);
      } else if (type == 'order' && orderId != null) {
        print('📍 Navigating to order: $orderId');
        NavigationService.navigateToOrder(orderId);
      } else {
        print('📍 No specific navigation for this notification type');
      }
    } catch (e) {
      print(
          '❌ [NotificationService] Error handling notification navigation: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null || token.isEmpty) return;
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'android',
        'appVersion': '1.0.0',
      }, SetOptions(merge: true));

      print('✅ [NotificationService] FCM token saved for user $_currentUserId');
    } catch (e) {
      print('❌ [NotificationService] Error saving FCM token: $e');
    }
  }

  static Future<void> _sendPushNotificationToUser({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    required String senderId,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (!userDoc.exists) {
        print('⚠️ [NotificationService] User not found: $receiverId');
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ [NotificationService] No FCM token for user: $receiverId');
        return;
      }

      print('📤 [NotificationService] Sending push to: $receiverId');

      // Show local notification
      await _showLocalNotification(
        title: 'New message from $senderName',
        body: messageText.length > 50
            ? '${messageText.substring(0, 50)}...'
            : messageText,
        payload: json.encode({
          'type': 'message',
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'receiverId': receiverId,
          'message': messageText,
        }),
        notificationType: 'message',
      );
    } catch (e) {
      print('❌ [NotificationService] Error sending push notification: $e');
    }
  }

  static Future<void> _subscribeToUserTopics(String userId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('user_$userId');
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('app_updates');

      print('✅ [NotificationService] Subscribed to topics for user $userId');
    } catch (e) {
      print('❌ [NotificationService] Error subscribing to topics: $e');
    }
  }

  static Future<void> _unsubscribeFromAllTopics() async {
    try {
      if (_currentUserId != null) {
        await _firebaseMessaging.unsubscribeFromTopic('user_$_currentUserId');
      }

      await _firebaseMessaging.unsubscribeFromTopic('all_users');
      await _firebaseMessaging.unsubscribeFromTopic('app_updates');

      print('✅ [NotificationService] Unsubscribed from all topics');
    } catch (e) {
      print('❌ [NotificationService] Error unsubscribing from topics: $e');
    }
  }

  static void _onNotificationTapped(String? payload) {
    try {
      if (payload != null && payload.isNotEmpty) {
        final data = json.decode(payload) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      print('❌ [NotificationService] Error handling notification tap: $e');
    }
  }

  static void _updateBadgeCount(int increment) {
    _badgeCount += increment;
    _badgeCountStreamController.add(_badgeCount);
  }

  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      _badgeCount = 0;
      _badgeCountStreamController.add(0);

      print('✅ [NotificationService] All notifications cleared');
    } catch (e) {
      print('❌ [NotificationService] Error clearing notifications: $e');
    }
  }

  static Future<void> clearBadge() async {
    _badgeCount = 0;
    _badgeCountStreamController.add(0);
  }

  static Future<NotificationSettings> getPermissionStatus() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  static Future<void> refreshFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      _currentFCMToken = token;
      await _saveTokenToFirestore(token);
      print('🔄 [NotificationService] FCM token refreshed: $token');
    } catch (e) {
      print('❌ [NotificationService] Error refreshing FCM token: $e');
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await getPermissionStatus();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('❌ [NotificationService] Error checking notification status: $e');
      return false;
    }
  }

  static Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  static Future<void> createTestNotification() async {
    try {
      if (_currentUserId == null) {
        print('⚠️ [NotificationService] No user logged in for test');
        return;
      }

      await FirebaseService.createTestNotification(_currentUserId!);

      await _showLocalNotification(
        title: 'Test Notification 🔔',
        body: 'This is a test notification from Akhdem Li',
        payload: json.encode({
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
        notificationType: 'test',
      );

      print('✅ [NotificationService] Test notification created');
    } catch (e) {
      print('❌ [NotificationService] Error creating test notification: $e');
    }
  }

  static void dispose() {
    _notificationStreamController.close();
    _badgeCountStreamController.close();
    _isInitialized = false;
    print('♻️ [NotificationService] Disposed');
  }
}

// ============================================================================
// BACKGROUND MESSAGE HANDLER
// ============================================================================

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🌙 [NotificationService] Background message received');

  try {
    await Firebase.initializeApp();

    // Create a local notifications plugin instance
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await localNotifications.initialize(initializationSettings);

    // Get notification data
    final data = message.data;
    final notification = message.notification;

    // Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Colors.red,
      icon: '@mipmap/ic_launcher',
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

    // Show notification
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification?.title ?? data['title'] ?? 'New Message',
      notification?.body ?? data['body'] ?? '',
      details,
      payload: json.encode(data),
    );

    print('✅ [NotificationService] Background notification handled');
  } catch (e) {
    print('❌ [NotificationService] Error in background handler: $e');
  }
}

// ============================================================================
// QUICK ACCESS
// ============================================================================

final notificationService = NotificationService();
