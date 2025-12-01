import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/UserModel.dart';

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

  /// Update user's location and address
  Future<void> updateUserLocation(
    String userId,
    double lat,
    double lng,
    String address,
    String wilaya,
    String commune,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'location': GeoPoint(lat, lng),
      'address': address,
      'wilaya': wilaya,
      'commune': commune,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update user's service categories
  Future<void> updateUserServices(
    String userId,
    List<String> categories,
    List<String> subServices,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'serviceCategories': categories,
      'subServices': subServices,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update subscription status
  Future<void> updateSubscriptionStatus(
    String userId,
    bool isActive,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'subscriptionActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
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

  /// Get user stats including address, total jobs, rating, etc.
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      Map<String, dynamic> userData = {};

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>? ?? {};

        // Get jobs statistics
        final jobsQuery = await _firestore
            .collection('jobs')
            .where('userId', isEqualTo: userId)
            .get();

        final completedJobsQuery = await _firestore
            .collection('jobs')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .get();

        // Calculate rating from reviews
        final reviewsQuery = await _firestore
            .collection('reviews')
            .where('targetUserId', isEqualTo: userId)
            .get();

        double averageRating = 0.0;
        if (reviewsQuery.docs.isNotEmpty) {
          double totalRating = 0;
          int validReviews = 0;

          for (final doc in reviewsQuery.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('rating') && data['rating'] != null) {
              totalRating += (data['rating'] as num).toDouble();
              validReviews++;
            }
          }

          if (validReviews > 0) {
            averageRating = totalRating / validReviews;
          }
        }

        return {
          'address': userData['address'] ?? '',
          'wilaya': userData['wilaya'] ?? '',
          'commune': userData['commune'] ?? '',
          'profession': userData['profession'] ?? '',
          'serviceCategories':
              List<String>.from(userData['serviceCategories'] ?? []),
          'subServices': List<String>.from(userData['subServices'] ?? []),
          'totalJobs': jobsQuery.docs.length,
          'completedJobs': completedJobsQuery.docs.length,
          'rating': averageRating,
          'name': userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'role': userData['role'] ?? 'client',
          'subscriptionActive': userData['subscriptionActive'] ?? false,
        };
      }

      return {};
    } catch (e) {
      print('Error getting user stats: $e');
      throw e;
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user role: $e');
      throw e;
    }
  }

  /// Get provider services (from separate collection)
  Future<List<Map<String, dynamic>>> getProviderServices(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error getting provider services: $e');
      throw e;
    }
  }

  /// Add new service
  Future<void> addService(
      String userId, Map<String, dynamic> serviceData) async {
    try {
      await _firestore.collection('services').add({
        'providerId': userId,
        ...serviceData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding service: $e');
      throw e;
    }
  }

  /// Update service
  Future<void> updateService(
      String serviceId, Map<String, dynamic> serviceData) async {
    try {
      await _firestore.collection('services').doc(serviceId).update({
        ...serviceData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating service: $e');
      throw e;
    }
  }

  /// Delete service
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
    } catch (e) {
      print('Error deleting service: $e');
      throw e;
    }
  }
}
