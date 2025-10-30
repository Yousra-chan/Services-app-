import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:async';
import '../models/usermodel.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> get userModelStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await fetchUserModel(user);
    });
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'This email address is already in use.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      default:
        return 'An unknown authentication error occurred.';
    }
  }

  Future<UserModel> _saveUserToFirestore(User user, {String? name}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }

    final userDoc = UserModel(
      uid: user.uid,
      name: name ?? user.displayName ?? 'New User',
      email: user.email ?? '',
      phone: '',
      role: 'client',
      photoUrl: user.photoURL ?? '',
      createdAt: Timestamp.now(),
      location: null,
      address: '',
    );

    await docRef.set(userDoc.toMap());
    return userDoc;
  }

  Future<UserModel> signup(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw AuthException("User registration failed.");

      try {
        final userModel = await _saveUserToFirestore(user, name: name);
        try {
          await user.sendEmailVerification();
        } catch (_) {}
        return userModel;
      } catch (e) {
        try {
          await user.delete();
        } catch (_) {}
        throw AuthException('Registration failed while saving user data.');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseAuthError(e));
    } catch (e) {
      throw AuthException("Registration failed.");
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw AuthException("Login failed.");

      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
        } catch (_) {}
        await _auth.signOut();
        throw AuthException(
          'Please verify your email. A new verification link has been sent.',
        );
      }

      final userModel = await fetchUserModel(user);
      if (userModel == null) {
        await _auth.signOut();
        throw AuthException("User profile not found.");
      }
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseAuthError(e));
    } catch (e) {
      throw AuthException("Login failed.");
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) throw AuthException("Google Sign-in failed.");

      return await _saveUserToFirestore(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseAuthError(e));
    } catch (e) {
      throw AuthException("Google Sign-in failed.");
    }
  }

  Future<UserModel> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential.identityToken == null) {
        throw AuthException("Apple Sign-in failed: Missing identity token.");
      }

      final AuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) throw AuthException("Apple Sign-in failed.");

      return await _saveUserToFirestore(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseAuthError(e));
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        throw AuthException('Apple sign-in was cancelled.');
      }
      throw AuthException("Apple Sign-in failed.");
    }
  }

  Future<UserModel?> fetchUserModel(User firebaseUser) async {
    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
