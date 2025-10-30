import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usermodel.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new user
  Future<void> createUser(UserModel user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set(user.toMap());
  }

  /// Update user profile
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  /// Fetch user by ID
  Future<UserModel?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Fetch all users (optional: by role)
  Future<List<UserModel>> getUsers({String? role}) async {
    Query query = _firestore.collection('users');
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  /// Update user's location
  Future<void> updateUserLocation(
    String userId,
    double lat,
    double lng,
    String address,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'location': GeoPoint(lat, lng),
      'address': address,
    });
  }

  /// Listen to user updates in real-time
  Stream<UserModel> listenUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.data()!, doc.id));
  }
}
