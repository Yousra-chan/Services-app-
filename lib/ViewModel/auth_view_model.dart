import 'package:flutter/material.dart';
import 'dart:async'; // Needed for StreamSubscription
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usermodel.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Holds the currently authenticated user's data from Firestore
  UserModel? _currentUser;

  // Expose the current user model
  UserModel? get currentUser => _currentUser;

  bool isLoading = false;
  String? errorMessage;

  // Stream to track the current UserModel for UI routing/state
  final StreamController<UserModel?> _userController =
      StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get userStream => _userController.stream;

  // Subscription to Firebase Auth state changes
  late StreamSubscription<User?> _authStateSubscription;

  AuthViewModel() {
    // Start listening to Firebase Auth state changes immediately
    _authStateSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );
  }

  // Handler for Firebase Auth state changes (login, logout, session restored)
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    isLoading = true;
    notifyListeners();

    if (firebaseUser != null) {
      // User is logged in (or session was restored). Fetch their data from Firestore.
      final userModel = await _authService.fetchUserModel(firebaseUser);
      _currentUser = userModel;
      _userController.add(userModel); // Notify listeners of the full UserModel
    } else {
      // User is logged out
      _currentUser = null;
      _userController.add(null);
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Crucial: Cancel the subscription and close the controller when the ViewModel is disposed
    _authStateSubscription.cancel();
    _userController.close();
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      _currentUser = user; // Set the current user after successful login
      _userController.add(user); // Notify stream listeners
      errorMessage = null;
    } on Exception catch (e) {
      errorMessage =
          e.toString().contains('firebase_auth')
              ? 'Invalid credentials or network error.'
              : e.toString();
      _currentUser = null;
      _userController.add(null);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String name, String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signup(name, email, password);
      _currentUser = user; // Set the current user after successful signup
      _userController.add(user); // Notify stream listeners
      errorMessage = null;
    } on Exception catch (e) {
      errorMessage =
          e.toString().contains('firebase_auth')
              ? 'Registration failed. Email might be in use.'
              : e.toString();
      _currentUser = null;
      _userController.add(null);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    // _onAuthStateChanged handles setting _currentUser to null, but we can call notifyListeners here for immediate UI update.
  }
}
