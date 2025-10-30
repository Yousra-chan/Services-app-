import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // FIX: Required for sin, cos, sqrt, atan2
import '../models/providermodel.dart';

class ProviderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new provider document
  Future<void> createProvider(ProviderModel provider) async {
    final docRef = _firestore.collection('providers').doc();
    // FIX: This now works because uid is NOT final in the model
    provider.uid = docRef.id;
    await docRef.set(provider.toMap());
  }

  /// Update existing provider document
  Future<void> updateProvider(ProviderModel provider) async {
    if (provider.uid == null) throw Exception('Provider ID is null');
    await _firestore
        .collection('providers')
        .doc(provider.uid)
        .update(provider.toMap());
  }

  /// Fetch all providers
  Future<List<ProviderModel>> getAllProviders() async {
    final snapshot = await _firestore.collection('providers').get();
    return snapshot.docs
        .map((doc) => ProviderModel.fromMap(doc.data(), doc.id)) // Pass doc.id
        .toList();
  }

  /// Fetch provider by ID
  Future<ProviderModel?> getProviderById(String id) async {
    final doc = await _firestore.collection('providers').doc(id).get();
    if (!doc.exists) return null;
    return ProviderModel.fromMap(doc.data()!, doc.id); // Pass doc.id
  }

  /// Fetch providers by service ID
  Future<List<ProviderModel>> getProvidersByService(String serviceId) async {
    final snapshot =
        await _firestore
            .collection('providers')
            .where('services', arrayContains: serviceId)
            .get();

    return snapshot.docs
        .map((doc) => ProviderModel.fromMap(doc.data(), doc.id)) // Pass doc.id
        .toList();
  }

  /// Fetch providers near a location within a radius (meters)
  Future<List<ProviderModel>> getProvidersNearby(
    double userLat,
    double userLng,
    double radiusMeters,
  ) async {
    final snapshot = await _firestore.collection('providers').get();

    final nearbyProviders =
        snapshot.docs
            .map((doc) {
              final provider = ProviderModel.fromMap(
                doc.data(),
                doc.id,
              ); // Pass doc.id
              if (provider.location == null) return null;

              double distance = _calculateDistance(
                userLat,
                userLng,
                provider.location!.latitude, // Use GeoPoint properties
                provider.location!.longitude, // Use GeoPoint properties
              );

              return distance <= radiusMeters ? provider : null;
            })
            .where((p) => p != null)
            .cast<ProviderModel>()
            .toList();

    return nearbyProviders;
  }

  /// Helper: calculate distance in meters between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // meters
    double dLat = _deg2rad(lat2 - lat1);
    double dLng = _deg2rad(lng2 - lng1);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLng / 2) * sin(dLng / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Helper: converts degrees to radians
  double _deg2rad(double deg) => deg * (pi / 180.0);
}
