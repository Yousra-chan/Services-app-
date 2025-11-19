import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _defaultChannelId = 'default_channel';
  static const String _chatChannelId = 'chat_channel';
  static const String _bookingChannelId = 'booking_channel';
  static const String _alertChannelId = 'alert_channel';

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    await localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _showNotification(message, localNotifications);
  }

  static Future<void> _showNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin localNotifications,
  ) async {
    try {
      final String channelId = _getChannelIdFromMessage(message);

      final NotificationDetails notificationDetails = NotificationDetails(
        android: _getAndroidChannelDetails(channelId),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> init() async {
    try {
      await _requestPermissions();
      _setupFCMListeners();
      await _initializeLocalNotifications();
      await _createNotificationChannels();
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  void _setupFCMListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message, _localNotifications);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    _messaging.onTokenRefresh.listen(_handleTokenRefresh);
  }

  static String _getChannelIdFromMessage(RemoteMessage message) {
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

  static AndroidNotificationDetails _getAndroidChannelDetails(
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

  Future<void> _createNotificationChannels() async {
    final channels = [
      const AndroidNotificationChannel(
        _defaultChannelId,
        'General Notifications',
        description: 'Important updates and announcements',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _chatChannelId,
        'Chat Notifications',
        description: 'Notifications for new chat messages',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        _bookingChannelId,
        'Booking Notifications',
        description: 'Notifications for booking updates',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _alertChannelId,
        'Alerts',
        description: 'Urgent alerts and emergencies',
        importance: Importance.max,
      ),
    ];

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      for (var channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
  }

  void _handleMessageNavigation(RemoteMessage message) {
    print('App opened from notification: ${message.data}');
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    print('Saving new FCM token: $newToken');
  }

  Future<String?> getDeviceToken() => _messaging.getToken();

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> setForegroundNotificationOptions() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> deleteAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
