import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channels for different types
  static const String _defaultChannelId = 'default_channel';
  static const String _chatChannelId = 'chat_channel';
  static const String _bookingChannelId = 'booking_channel';
  static const String _alertChannelId = 'alert_channel';

  /// Initialize FCM and local notifications
  Future<void> init() async {
    try {
      print('Initializing notification service...');

      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, // For iOS - request full permission
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission for notifications');
      } else {
        print('User denied notification permission');
      }

      // Initialize local notifications with platform-specific settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response);
        },
      );

      // Create notification channels
      await _createNotificationChannels();

      // 🧠 Handle background and terminated notifications
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.messageId}');
        _showLocalNotification(message);
      });

      // When app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from notification: ${message.data}');
        _handleMessageNavigation(message);
      });

      // 💨 Token refresh handling
      _messaging.onTokenRefresh.listen((String newToken) {
        print('FCM token refreshed: $newToken');
        _handleTokenRefresh(newToken);
      });

      // Get initial message if app was opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from terminated state with notification');
        _handleMessageNavigation(initialMessage);
      }

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  /// 🧠 Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Handling a background message: ${message.messageId}');

    // Initialize local notifications in background
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    await localNotifications.initialize(initSettings);

    // Show notification in background
    await _showBackgroundNotification(message, localNotifications);
  }

  /// Show notification from background handler
  static Future<void> _showBackgroundNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin localNotifications,
  ) async {
    try {
      final String channelId = _getChannelIdFromMessageStatic(message);
      final AndroidNotificationDetails androidDetails =
          _getAndroidChannelDetailsStatic(channelId);
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      await localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Error showing background notification: $e');
    }
  }

  /// 🧩 Create multiple notification channels
  Future<void> _createNotificationChannels() async {
    try {
      // Default channel
      const AndroidNotificationChannel defaultChannel =
          AndroidNotificationChannel(
            _defaultChannelId,
            'General Notifications',
            description: 'Important updates and announcements',
            importance: Importance.high,
          );

      // Chat channel
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        _chatChannelId,
        'Chat Notifications',
        description: 'Notifications for new chat messages',
        importance: Importance.max,
      );

      // Booking channel
      const AndroidNotificationChannel bookingChannel =
          AndroidNotificationChannel(
            _bookingChannelId,
            'Booking Notifications',
            description: 'Notifications for booking updates',
            importance: Importance.high,
          );

      // Alert channel
      const AndroidNotificationChannel alertChannel =
          AndroidNotificationChannel(
            _alertChannelId,
            'Alerts',
            description: 'Urgent alerts and emergencies',
            importance: Importance.max,
          );

      final androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(defaultChannel);
        await androidPlugin.createNotificationChannel(chatChannel);
        await androidPlugin.createNotificationChannel(bookingChannel);
        await androidPlugin.createNotificationChannel(alertChannel);
      }

      print('Notification channels created successfully');
    } catch (e) {
      print('Error creating notification channels: $e');
    }
  }

  /// 🔒 Show local notification with error handling
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final String channelId = _getChannelIdFromMessage(message);
      final AndroidNotificationDetails androidDetails =
          _getAndroidChannelDetails(channelId);

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        notificationDetails,
        payload: message.data.toString(),
      );

      print('Local notification shown successfully for channel: $channelId');
    } catch (e) {
      print("Error showing local notification: $e");
    }
  }

  /// 🧩 Get appropriate channel ID based on message type
  String _getChannelIdFromMessage(RemoteMessage message) {
    final String? type = message.data['type'];

    switch (type) {
      case 'chat':
      case 'message':
        return _chatChannelId;
      case 'booking':
      case 'appointment':
        return _bookingChannelId;
      case 'alert':
      case 'emergency':
        return _alertChannelId;
      default:
        return _defaultChannelId;
    }
  }

  /// 🧩 Static version for background handler
  static String _getChannelIdFromMessageStatic(RemoteMessage message) {
    final String? type = message.data['type'];

    switch (type) {
      case 'chat':
      case 'message':
        return _chatChannelId;
      case 'booking':
      case 'appointment':
        return _bookingChannelId;
      case 'alert':
      case 'emergency':
        return _alertChannelId;
      default:
        return _defaultChannelId;
    }
  }

  /// 🧩 Get Android channel details
  AndroidNotificationDetails _getAndroidChannelDetails(String channelId) {
    switch (channelId) {
      case _chatChannelId:
        return const AndroidNotificationDetails(
          _chatChannelId,
          'Chat Notifications',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );
      case _bookingChannelId:
        return const AndroidNotificationDetails(
          _bookingChannelId,
          'Booking Notifications',
          channelDescription: 'Notifications for booking updates',
          importance: Importance.high,
          priority: Priority.high,
        );
      case _alertChannelId:
        return const AndroidNotificationDetails(
          _alertChannelId,
          'Alerts',
          channelDescription: 'Urgent alerts and emergencies',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
        );
      default:
        return const AndroidNotificationDetails(
          _defaultChannelId,
          'General Notifications',
          channelDescription: 'Important updates and announcements',
          importance: Importance.high,
          priority: Priority.defaultPriority,
        );
    }
  }

  /// 🧩 Static version for background handler
  static AndroidNotificationDetails _getAndroidChannelDetailsStatic(
    String channelId,
  ) {
    switch (channelId) {
      case _chatChannelId:
        return const AndroidNotificationDetails(
          _chatChannelId,
          'Chat Notifications',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );
      case _bookingChannelId:
        return const AndroidNotificationDetails(
          _bookingChannelId,
          'Booking Notifications',
          channelDescription: 'Notifications for booking updates',
          importance: Importance.high,
          priority: Priority.high,
        );
      case _alertChannelId:
        return const AndroidNotificationDetails(
          _alertChannelId,
          'Alerts',
          channelDescription: 'Urgent alerts and emergencies',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
        );
      default:
        return const AndroidNotificationDetails(
          _defaultChannelId,
          'General Notifications',
          channelDescription: 'Important updates and announcements',
          importance: Importance.high,
          priority: Priority.defaultPriority,
        );
    }
  }

  /// 🧭 Handle notification tap and navigation
  void _handleNotificationTap(NotificationResponse response) {
    try {
      print('Notification tapped with payload: ${response.payload}');

      final String? payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        // Parse the payload and navigate accordingly
        // Example: Navigate to specific screen based on data
        _navigateFromNotification(payload);
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  /// 🧭 Handle message navigation
  void _handleMessageNavigation(RemoteMessage message) {
    try {
      print('Handling message navigation: ${message.data}');

      final Map<String, dynamic> data = message.data;
      final String? type = data['type'];
      final String? id = data['id'];

      // Navigate based on message type and data
      if (type != null && id != null) {
        switch (type) {
          case 'chat':
            // NavigationService.instance.navigateTo('/chat', arguments: {'chatId': id});
            print('Navigate to chat: $id');
            break;
          case 'booking':
            // NavigationService.instance.navigateTo('/booking', arguments: {'bookingId': id});
            print('Navigate to booking: $id');
            break;
          case 'alert':
            // NavigationService.instance.navigateTo('/alerts', arguments: {'alertId': id});
            print('Navigate to alert: $id');
            break;
          default:
            // NavigationService.instance.navigateTo('/notifications');
            print('Navigate to notifications');
        }
      }
    } catch (e) {
      print('Error handling message navigation: $e');
    }
  }

  /// 🧭 Navigate from notification payload
  void _navigateFromNotification(String payload) {
    try {
      // Parse your payload and navigate accordingly
      // This is a simplified example - adapt to your navigation system
      print('Navigating from notification payload: $payload');

      // Example implementation:
      // final Map<String, dynamic> data = json.decode(payload);
      // final String route = data['route'] ?? '/home';
      // final Map<String, dynamic> arguments = data['arguments'] ?? {};
      // NavigationService.instance.navigateTo(route, arguments: arguments);
    } catch (e) {
      print('Error navigating from notification: $e');
    }
  }

  /// 💨 Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      print('Saving new FCM token: $newToken');

      // TODO: Save new token to Firestore or backend
      // Example:
      // await FirebaseFirestore.instance.collection('users').doc(userId).update({
      //   'fcmToken': newToken,
      //   'tokenUpdatedAt': FieldValue.serverTimestamp(),
      // });

      print('FCM token updated successfully');
    } catch (e) {
      print('Error saving new FCM token: $e');
    }
  }

  /// Get FCM token for the device
  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Set foreground notification presentation options (iOS)
  Future<void> setForegroundNotificationOptions() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true, // Show alert when in foreground
          badge: true, // Update badge when in foreground
          sound: true, // Play sound when in foreground
        );
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('All notifications deleted');
    } catch (e) {
      print('Error deleting notifications: $e');
    }
  }

  /// Debug method to print current notification settings
  Future<void> debugNotificationSettings() async {
    try {
      print('=== Notification Settings Debug ===');
      final token = await getDeviceToken();
      print('FCM Token: $token');
      print('APNS Token: ${await _messaging.getAPNSToken()}');
      print('=== End Debug ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }
}
