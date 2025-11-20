import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';

class AuthViewModel with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthViewModel() {
    _initializeAuthState();
  }

  // ============ PUBLIC AUTH METHODS ============

  Future<UserModel?> login(String email, String password) async {
    return _executeAuthOperation(() async {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _fetchAndSetUser(userCredential.user!.uid);
    }, 'Login');
  }

  Future<UserModel?> signInWithGoogle() async {
    return _executeAuthOperation(() async {
      final userModel = await _authService.signInWithGoogle();
      _setUser(userModel);
      return userModel;
    }, 'Google sign-in');
  }

  Future<UserModel?> signInWithApple() async {
    return _executeAuthOperation(() async {
      final userModel = await _authService.signInWithApple();
      _setUser(userModel);
      return userModel;
    }, 'Apple sign-in');
  }

  Future<UserModel?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String address,
    double? lat, // Make these optional to match register page
    double? lon,
  }) async {
    return _executeAuthOperation(() async {
      final userModel = await _authService.signup(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        address: address,
        lat: lat, // Pass the optional parameters
        lon: lon,
      );
      _setUser(userModel);
      return userModel;
    }, 'Sign up');
  }

  Future<void> logout() async {
    return _executeOperation(() async {
      await _authService.logout();
      _clearUser();
    }, 'Logout');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    return _executeOperation(
      () => _authService.sendPasswordResetEmail(email),
      'Password reset',
    );
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    return _executeOperation(() async {
      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    }, 'Profile update');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============ PRIVATE METHODS ============

  Future<void> _initializeAuthState() async {
    await _executeOperation(() async {
      _authService.authStateChanges.listen(_handleAuthStateChange);

      final firebaseUser = _authService.getCurrentUser();
      if (firebaseUser != null) {
        await _fetchCurrentUser(firebaseUser.uid);
      }
    }, 'Initialization');
  }

  void _handleAuthStateChange(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _fetchCurrentUser(firebaseUser.uid);
    } else {
      _clearUser();
    }
  }

  Future<void> _fetchCurrentUser(String uid) async {
    try {
      final userModel = await _userService.getUserById(uid);
      if (userModel != null) {
        _setUser(userModel);
      } else {
        _setError('User profile not found');
      }
    } catch (e) {
      _setError('Failed to load user profile: $e');
    }
  }

  Future<UserModel?> _fetchAndSetUser(String uid) async {
    try {
      final userModel = await _userService.getUserById(uid);
      _setUser(userModel);
      return userModel;
    } catch (e) {
      debugPrint('Warning: Failed to load UserModel profile: $e');
      _setError('User profile not found');
      return null;
    }
  }

  // ============ EXECUTION HELPERS ============

  Future<UserModel?> _executeAuthOperation(
    Future<UserModel?> Function() operation,
    String operationName,
  ) async {
    try {
      _setLoading(true);
      _setError(null);
      return await operation();
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getFirebaseAuthErrorMessage(e);
      _setError('$operationName failed: $errorMessage');
      return null;
    } catch (e) {
      _setError('$operationName failed: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _executeOperation(
    Future<void> Function() operation,
    String operationName,
  ) async {
    try {
      _setLoading(true);
      _setError(null);
      await operation();
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getFirebaseAuthErrorMessage(e);
      _setError('$operationName failed: $errorMessage');
      rethrow;
    } catch (e) {
      _setError('$operationName failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============ STATE MANAGEMENT ============

  void _setUser(UserModel? user) {
    _currentUser = user;
    _error = null;
    notifyListeners();
  }

  void _clearUser() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // ============ ERROR MAPPING ============

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    const errorMessages = {
      'user-not-found': 'No user found with this email address',
      'wrong-password': 'Incorrect password',
      'invalid-email': 'Invalid email address',
      'user-disabled': 'This account has been disabled',
      'email-already-in-use': 'An account already exists with this email',
      'weak-password': 'Password is too weak',
      'network-request-failed': 'Network error. Please check your connection',
    };

    return errorMessages[e.code] ?? 'Authentication failed: ${e.message}';
  }
}
