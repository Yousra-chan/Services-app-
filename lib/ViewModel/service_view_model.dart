import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/ServicesModel.dart';

class ServiceViewModel with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Service> _userServices = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Service> get userServices => _userServices;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // FIXED: Create service using only users collection
  Future<bool> createService({
    required String providerId,
    required String title,
    required String description,
    required String category,
    required String subcategory,
    required double price,
    required String priceUnit,
    required String location,
    required double? latitude,
    required double? longitude,
    required List<String> tags,
  }) async {
    try {
      setLoading(true);
      _error = null;

      // Create service document
      final serviceId =
          FirebaseFirestore.instance.collection('services').doc().id;

      final service = Service(
        id: serviceId,
        providerId: providerId,
        title: title,
        description: description,
        category: category,
        subcategory: subcategory,
        price: price,
        priceUnit: priceUnit,
        location: location,
        latitude: latitude,
        longitude: longitude,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        images: [],
        isActive: true,
        rating: 0.0,
        totalReviews: 0,
      );

      // 1. Save service to services collection
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .set(service.toMap());

      // 2. Update user document with service reference
      await FirebaseFirestore.instance
          .collection('users')
          .doc(providerId)
          .update({
        'serviceIds': FieldValue.arrayUnion([serviceId]),
        'updatedAt': Timestamp.now(),
      });

      // 3. Add to local services list
      _userServices.add(service);

      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setLoading(false);
      _error = 'Failed to create service: $e';
      return false;
    }
  }

  // FIXED: Get services by user ID (using users collection)
  Future<List<Service>> getServicesByUserId(String userId) async {
    try {
      setLoading(true);
      _error = null;

      // Method 1: Get service IDs from user document first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      List<String> serviceIds = [];

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        serviceIds = List<String>.from(userData['serviceIds'] ?? []);
      }

      if (serviceIds.isNotEmpty) {
        // Get services by their IDs
        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('services')
            .where('id', whereIn: serviceIds)
            .get();

        _userServices = servicesSnapshot.docs
            .map((doc) => Service.fromMap(doc.data()))
            .toList();
      } else {
        // Fallback: Get services directly by providerId
        final snapshot = await FirebaseFirestore.instance
            .collection('services')
            .where('providerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

        _userServices =
            snapshot.docs.map((doc) => Service.fromMap(doc.data())).toList();
      }

      setLoading(false);
      notifyListeners();
      return _userServices;
    } catch (e) {
      setLoading(false);
      _error = 'Failed to fetch user services: $e';
      _userServices = [];
      notifyListeners();
      return [];
    }
  }

  // Alternative: Direct query by providerId (simpler)
  Future<List<Service>> getServicesByProviderId(String providerId) async {
    try {
      setLoading(true);
      _error = null;

      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();

      _userServices =
          snapshot.docs.map((doc) => Service.fromMap(doc.data())).toList();

      setLoading(false);
      notifyListeners();
      return _userServices;
    } catch (e) {
      setLoading(false);
      _error = 'Failed to fetch services: $e';
      _userServices = [];
      notifyListeners();
      return [];
    }
  }

  // FIXED: Delete service
  Future<bool> deleteService(String serviceId, String userId) async {
    try {
      setLoading(true);
      _error = null;

      // Verify the service belongs to the user
      final serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .get();

      if (!serviceDoc.exists) {
        _error = 'Service not found';
        setLoading(false);
        return false;
      }

      final serviceData = serviceDoc.data();
      if (serviceData?['providerId'] != userId) {
        _error = 'You can only delete your own services';
        setLoading(false);
        return false;
      }

      // 1. Delete from services collection
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .delete();

      // 2. Remove from user's serviceIds array
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'serviceIds': FieldValue.arrayRemove([serviceId]),
        'updatedAt': Timestamp.now(),
      });

      // 3. Remove from local list
      _userServices.removeWhere((service) => service.id == serviceId);

      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setLoading(false);
      _error = 'Failed to delete service: $e';
      return false;
    }
  }

  // Update UserModel to mark as provider when creating first service
  Future<bool> markUserAsProvider(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': 'provider',
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      _error = 'Failed to update user role: $e';
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearServices() {
    _userServices = [];
    notifyListeners();
  }
}
