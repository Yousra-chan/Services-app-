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

  // ============ INITIALIZATION ============
  Future<void> _initializeAuthState() async {
    try {
      _setLoading(true);

      // Listen to auth state changes
      _authService.authStateChanges.listen(_handleAuthStateChange);

      // Check initial state
      final firebaseUser = _authService.getCurrentUser();
      if (firebaseUser != null) {
        await _fetchCurrentUser(firebaseUser.uid);
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _handleAuthStateChange(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _fetchCurrentUser(firebaseUser.uid);
    } else {
      _currentUser = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> _fetchCurrentUser(String uid) async {
    try {
      final userModel = await _userService.getUserById(uid);
      if (userModel != null) {
        _currentUser = userModel;
        _error = null;
        notifyListeners();
      } else {
        _setError('User profile not found');
      }
    } catch (e) {
      _setError('Failed to load user profile: $e');
    }
  }

  // ============ AUTH METHODS ============
  Future<UserModel?> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      // 1. Firebase authentication
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String uid = userCredential.user!.uid;

      // 2. Fetch user profile
      try {
        final userModel = await _userService.getUserById(uid);
        _currentUser = userModel;
        _error = null;
        notifyListeners();
        return userModel;
      } catch (profileError) {
        print('Warning: Failed to load UserModel profile: $profileError');
        _setError('User profile not found');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getFirebaseAuthErrorMessage(e);
      _setError(errorMessage);
      return null;
    } catch (e) {
      _setError('Login failed: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final userModel = await _authService.signInWithGoogle();
      _currentUser = userModel;
      _error = null;
      notifyListeners();
      return userModel;
    } catch (e) {
      _setError('Google sign-in failed: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> signInWithApple() async {
    try {
      _setLoading(true);
      _setError(null);

      final userModel = await _authService.signInWithApple();
      _currentUser = userModel;
      _error = null;
      notifyListeners();
      return userModel;
    } catch (e) {
      _setError('Apple sign-in failed: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String address,
    double? lat,
    double? lon,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final userModel = await _authService.signup(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        address: address,
        lat: lat,
        lon: lon,
      );
      _currentUser = userModel;
      _error = null;
      notifyListeners();
      return userModel;
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getFirebaseAuthErrorMessage(e);
      _setError(errorMessage);
      return null;
    } catch (e) {
      _setError('Sign up failed: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.logout();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getFirebaseAuthErrorMessage(e);
      _setError(errorMessage);
      rethrow;
    } catch (e) {
      _setError('Password reset failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _setLoading(true);
      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============ ERROR HANDLING ============
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============ PRIVATE HELPERS ============
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
