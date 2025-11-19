import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/screens/auth/login/login_screen.dart';
import 'package:myapp/screens/navigator_bottom.dart';
import 'package:myapp/screens/onboarding/onboarding_screen.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Firebase
    await Firebase.initializeApp();

    // 2. Setup Firebase Cloud Messaging handlers
    FirebaseMessaging.onBackgroundMessage(
      NotificationService.firebaseMessagingBackgroundHandler,
    );

    // 3. Initialize local notification service
    await NotificationService().init();

    runApp(const MyApp());
  } catch (error) {
    // Catch errors during core Firebase/Notification setup
    debugPrint('Fatal initialization error: $error');
    runApp(
      const ErrorApp(
        initializationError:
            'Failed to initialize Firebase or Notification Services.',
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Akhdem-Li',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) => const NavigatorBottom(),
          '/login': (context) => const LoginScreen(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String initializationError;
  const ErrorApp({super.key, required this.initializationError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.amber.shade700,
              ),
              const SizedBox(height: 20),
              const Text(
                'Critical Startup Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                initializationError,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
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
      debugPrint('Error checking onboarding status: $error');
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = false; // Default to false on error
          _isCheckingOnboarding = false;
        });
      }
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
    // If we're still loading and no user data, show loading
    if (authViewModel.isLoading && authViewModel.currentUser == null) {
      return _buildLoadingScreen('Checking user session...');
    }

    // If there's an error and no user, show error screen
    if (authViewModel.error != null && authViewModel.currentUser == null) {
      return _buildErrorScreen(authViewModel.error!);
    }

    // If user is authenticated, show main app
    if (authViewModel.currentUser != null) {
      return _buildAuthenticatedApp(authViewModel.currentUser!);
    }

    // User is not authenticated, show login screen
    return const LoginScreen();
  }

  Widget _buildAuthenticatedApp(UserModel user) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatViewModel>(
          create: (context) => ChatViewModel(userId: user.uid),
          lazy: false, // Initialize immediately
        ),
      ],
      child: const NavigatorBottom(),
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String errorMessage) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Authentication Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Clear error and retry
                final authViewModel =
                    Provider.of<AuthViewModel>(context, listen: false);
                authViewModel.clearError();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Go to login screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
