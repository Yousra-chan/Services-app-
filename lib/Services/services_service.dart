import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/servicesmodel.dart';

class ServicesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new service
  Future<void> createService(ServiceModel service) async {
    final docRef = _firestore.collection('services').doc();
    // Assign the generated Firestore ID to the model
    service.id = docRef.id;
    await docRef.set(service.toMap());
  }

  /// Update existing service
  Future<void> updateService(ServiceModel service) async {
    // Using service.id which must be set for updates
    if (service.id == null || service.id!.isEmpty) {
      throw Exception("Service ID is required for update.");
    }
    // Update only the map data, excluding the ID if toMap() includes it
    await _firestore
        .collection('services')
        .doc(service.id)
        .update(service.toMap());
  }

  /// Delete a service
  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  /// Fetch all services
  Future<List<ServiceModel>> getAllServices() async {
    final snapshot = await _firestore.collection('services').get();
    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Fetch services by category
  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    final snapshot =
        await _firestore
            .collection('services')
            .where('category', isEqualTo: category)
            .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Fetch services offered by a specific provider
  Future<List<ServiceModel>> getServicesByProvider(String providerId) async {
    final snapshot =
        await _firestore
            .collection('services')
            .where('providerId', isEqualTo: providerId)
            .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
