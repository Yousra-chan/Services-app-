import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/ViewModel/unread_message_view_model.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/screens/auth/login/login_screen.dart';
import 'package:myapp/screens/navigator_bottom.dart';
import 'package:myapp/screens/onboarding/onboarding_screen.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 Starting app initialization...');

    // 1. Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // 2. Setup Firebase Cloud Messaging handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background message handler set up');

    // 3. Initialize local notification service
    await NotificationService.initialize();
    print('✅ Notification service initialized');

    // 4. Setup FCM and get token
    await setupFirebaseMessaging();
    print('✅ Firebase Messaging setup complete');

    runApp(const MyApp());
  } catch (error) {
    // Catch errors during core Firebase/Notification setup
    debugPrint('❌ Fatal initialization error: $error');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => UnreadMessagesViewModel()),
        ],
        child: const MyApp(),
      ),
    );
  }
}

// Setup Firebase Messaging
// Setup Firebase Messaging
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions
  try {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false,
    );

    print('🔔 Notification permission: ${settings.authorizationStatus}');
  } catch (e) {
    print('❌ Permission error: $e');
  }

  // Get FCM token
  try {
    String? token = await messaging.getToken();
    print('🔔 FCM Token: $token');

    // FIX: Check if token is not null before saving
    if (token != null) {
      await saveTokenToFirestore(token);
    } else {
      print('⚠️ FCM Token is null');
    }
  } catch (e) {
    print('❌ Token error: $e');
  }

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔔 Received message in foreground');
    print('🔔 Message title: ${message.notification?.title}');
    print('🔔 Message body: ${message.notification?.body}');

    // Show local notification
    NotificationService.showNotification(
      title: message.notification?.title ?? 'Akhdem Li',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data['chatId'] ?? '',
    );
  });
}

// Save token to Firestore
Future<void> saveTokenToFirestore(String token) async {
  try {
    // This will be used when we have a user logged in
    print('✅ FCM Token ready to save: $token');
    // We'll save it when user logs in, in the AuthViewModel
  } catch (e) {
    print('❌ Error saving FCM token: $e');
  }
}

// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Handling a background message: ${message.messageId}");

  // Show notification even when app is in background
  await NotificationService.showNotification(
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? '',
    payload: message.data['chatId'] ?? '',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        ChangeNotifierProvider(create: (context) => UnreadMessagesViewModel()),
      ],
      child: MaterialApp(
        title: 'Akhdem-Li',
        navigatorKey: navigatorKey, // Add this for notification navigation
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) => const NavigatorBottom(),
          '/login': (context) => const LoginScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingOnboarding = true;
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    _setupNotificationInteractions();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool hasSeenOnboarding =
          prefs.getBool('hasSeenOnboarding') ?? false;

      if (mounted) {
        setState(() {
          _hasSeenOnboarding = hasSeenOnboarding;
          _isCheckingOnboarding = false;
        });
      }
    } catch (error) {
      debugPrint('❌ Error checking onboarding status: $error');
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = false; // Default to false on error
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  void _setupNotificationInteractions() {
    print('🔔 Setting up notification interactions...');

    // Handle when app is opened from terminated state via notification
    NotificationService.handleInitialMessage();

    // Handle when app is in background and notification is clicked
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened from background via notification');
      _handleNotificationNavigation(message.data);
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final type = data['type'];

    print('🔔 Notification data: $data');

    if (chatId != null && type == 'message') {
      // Navigate to chat screen when notification is clicked
      navigatorKey.currentState?.pushNamed('/home');
      // You might want to add additional navigation to specific chat
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Show loading while checking onboarding status
    if (_isCheckingOnboarding) {
      return _buildLoadingScreen('Loading app...');
    }

    // Show onboarding if user hasn't seen it
    if (_hasSeenOnboarding == false) {
      return const OnboardingScreen();
    }

    // Handle auth state
    return _buildAuthState(authViewModel);
  }

  Widget _buildAuthState(AuthViewModel authViewModel) {
    // If we're still loading the initial auth state, show loading
    if (authViewModel.isLoading && authViewModel.currentUser == null) {
      return _buildLoadingScreen('Checking user session...');
    }

    // If there's an error during initial auth check and no user, show error screen
    if (authViewModel.error != null && authViewModel.currentUser == null) {
      // Only show error if it's not related to ongoing operations
      if (!authViewModel.error!.contains('Login failed') &&
          !authViewModel.error!.contains('Sign up failed')) {
        return _buildErrorScreen(authViewModel.error!);
      }
    }

    // If user is authenticated, show main app
    if (authViewModel.currentUser != null) {
      return _buildAuthenticatedApp(authViewModel.currentUser!);
    }

    // User is not authenticated, show login screen
    return const LoginScreen();
  }

  Widget _buildAuthenticatedApp(UserModel user) {
    // Save FCM token when user is authenticated
    _saveUserFCMToken(user.uid);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatViewModel>(
          create: (context) => ChatViewModel(userId: user.uid),
          lazy: false,
        ),
        // Add other providers as needed
      ],
      child: const NavigatorBottom(),
    );
  }

  Future<void> _saveUserFCMToken(String userId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ FCM Token saved for user: $userId');
    } catch (e) {
      print('❌ Error saving user FCM token: $e');
    }
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String errorMessage) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 20),
              const Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  final authViewModel =
                      Provider.of<AuthViewModel>(context, listen: false);
                  authViewModel.clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Retry Connection'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Go to Login',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
