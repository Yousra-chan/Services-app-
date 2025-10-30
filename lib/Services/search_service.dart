import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/providermodel.dart';
import '../models/servicesmodel.dart'; // Assuming this model also expects doc.id

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Provider Search ---

  /// Search providers by profession or name
  Future<List<ProviderModel>> searchProvidersByProfessionOrName(
    String query,
  ) async {
    final lowerCaseQuery = query.toLowerCase();
    // Standard Firestore prefix search for case-insensitive startWith
    final endQuery = '$lowerCaseQuery\uf8ff';

    // 1. Search by Profession (Index required for profession filter)
    // Note: Firestore queries are case-sensitive by default, so it's best to
    // store a lowercase field in Firestore for case-insensitive searching.
    final snapshotByProfession =
        await _firestore
            .collection('providers')
            .where('profession', isGreaterThanOrEqualTo: lowerCaseQuery)
            .where('profession', isLessThanOrEqualTo: endQuery)
            .get();

    // 2. Search by Name (Index required for name filter)
    final snapshotByName =
        await _firestore
            .collection('providers')
            .where('name', isGreaterThanOrEqualTo: lowerCaseQuery)
            .where('name', isLessThanOrEqualTo: endQuery)
            .get();

    final allDocs = [...snapshotByProfession.docs, ...snapshotByName.docs];

    // Remove duplicates using a Map to ensure unique document IDs
    final uniqueProvidersMap = <String, ProviderModel>{};
    for (var doc in allDocs) {
      // FIX: Passing doc.data() and doc.id
      uniqueProvidersMap[doc.id] = ProviderModel.fromMap(doc.data(), doc.id);
    }

    return uniqueProvidersMap.values.toList();
  }

  // --- Service Search ---

  /// Search services by name
  Future<List<ServiceModel>> searchServicesByName(String query) async {
    final lowerCaseQuery = query.toLowerCase();
    final endQuery = '$lowerCaseQuery\uf8ff';

    final snapshot =
        await _firestore
            .collection('services')
            .where('name', isGreaterThanOrEqualTo: lowerCaseQuery)
            .where('name', isLessThanOrEqualTo: endQuery)
            .get();

    return snapshot.docs
        // FIX: Passing doc.data() and doc.id
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Search services by exact category match
  Future<List<ServiceModel>> searchServicesByCategory(String category) async {
    final snapshot =
        await _firestore
            .collection('services')
            .where('category', isEqualTo: category)
            .get();

    return snapshot.docs
        // FIX: Passing doc.data() and doc.id
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
