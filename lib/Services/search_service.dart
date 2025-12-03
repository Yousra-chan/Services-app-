import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/models/ServicesModel.dart';
import 'package:myapp/services/categories_service.dart';
import 'dart:math';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoriesService _categoriesService = CategoriesService();

  /// Search providers by profession or name
  Future<List<ProviderModel>> searchProvidersByProfessionOrName(
    String query,
  ) async {
    try {
      if (query.isEmpty) return [];

      final lowerQuery = query.toLowerCase();

      // Search in users collection where role = 'provider'
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .get();

      final results = <ProviderModel>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final name = data['name']?.toString().toLowerCase() ?? '';
        final profession = data['profession']?.toString().toLowerCase() ?? '';

        // Check if query matches name or profession
        if (name.contains(lowerQuery) || profession.contains(lowerQuery)) {
          results.add(ProviderModel.fromFirestore(data, doc.id));
        }
      }

      return results;
    } catch (e) {
      print('Error searching providers: $e');
      return [];
    }
  }

  /// Search services by title, description, category, or subcategory
  Future<List<Service>> searchServices(String query) async {
    try {
      final lowerQuery = query.toLowerCase();

      final snapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      final results = <Service>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final title = data['title']?.toString().toLowerCase() ?? '';
        final description = data['description']?.toString().toLowerCase() ?? '';
        final category = data['category']?.toString().toLowerCase() ?? '';
        final subcategory = data['subcategory']?.toString().toLowerCase() ?? '';

        // Check if query matches any field
        if (title.contains(lowerQuery) ||
            description.contains(lowerQuery) ||
            category.contains(lowerQuery) ||
            subcategory.contains(lowerQuery)) {
          results.add(Service.fromMap({...data, 'id': doc.id}));
        }
      }

      return results;
    } catch (e) {
      print('Error searching services: $e');
      return [];
    }
  }

  /// Search providers with filters
  Future<List<ProviderModel>> searchProvidersWithFilters(
    Map<String, dynamic> filters,
  ) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider');

      // Apply filters
      if (filters.containsKey('wilaya') && filters['wilaya'] != null) {
        query = query.where('wilaya', isEqualTo: filters['wilaya']);
      }

      if (filters.containsKey('commune') && filters['commune'] != null) {
        query = query.where('commune', isEqualTo: filters['commune']);
      }

      // Note: Category filtering requires JOIN with services collection
      // We'll handle this separately
      if (filters.containsKey('category') && filters['category'] != null) {
        return await searchProvidersByCategoryWithFilters(filters);
      }

      if (filters.containsKey('minRating') && filters['minRating'] != null) {
        query = query.where(
          'rating',
          isGreaterThanOrEqualTo: filters['minRating'],
        );
      }

      if (filters.containsKey('subscriptionActive') &&
          filters['subscriptionActive'] != null) {
        query = query.where(
          'subscriptionActive',
          isEqualTo: filters['subscriptionActive'],
        );
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          // Return a default ProviderModel or throw an exception
          return ProviderModel(
            name: 'Unknown',
            profession: 'Unknown',
            address: '',
            wilaya: '',
            commune: '',
            phone: '',
            whatsapp: '',
            description: '',
            photoUrl: '',
            serviceIds: [],
          );
        }
        return ProviderModel.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error searching providers with filters: $e');
      return [];
    }
  }

  /// Search providers by category with other filters
  Future<List<ProviderModel>> searchProvidersByCategoryWithFilters(
    Map<String, dynamic> filters,
  ) async {
    try {
      final category = filters['category'] as String?;
      if (category == null || category.isEmpty) return [];

      // Get all services in this category
      Query servicesQuery = _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true);

      // Apply subcategory filter if provided
      if (filters.containsKey('subcategory') &&
          filters['subcategory'] != null) {
        servicesQuery = servicesQuery.where(
          'subcategory',
          isEqualTo: filters['subcategory'],
        );
      }

      final servicesSnapshot = await servicesQuery.get();

      if (servicesSnapshot.docs.isEmpty) return [];

      // Get unique provider IDs
      final providerIds = servicesSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['providerId'] as String?;
          })
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();

      // Get providers with other filters
      final providers = <ProviderModel>[];

      for (var providerId in providerIds) {
        if (providerId == null) continue;

        final providerDoc = await _firestore
            .collection('users')
            .doc(providerId)
            .get();

        if (!providerDoc.exists) {
          continue;
        }

        final data = providerDoc.data();
        if (data == null) continue;

        // Check if user is a provider
        final role = data['role'] as String?;
        if (role != 'provider') {
          continue;
        }

        // Apply other filters
        bool passesFilters = true;

        if (filters.containsKey('wilaya') && filters['wilaya'] != null) {
          final wilaya = data['wilaya'] as String?;
          if (wilaya != filters['wilaya']) {
            passesFilters = false;
          }
        }

        if (filters.containsKey('commune') && filters['commune'] != null) {
          final commune = data['commune'] as String?;
          if (commune != filters['commune']) {
            passesFilters = false;
          }
        }

        if (filters.containsKey('minRating') && filters['minRating'] != null) {
          final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          if (rating < (filters['minRating'] as num).toDouble()) {
            passesFilters = false;
          }
        }

        if (filters.containsKey('subscriptionActive') &&
            filters['subscriptionActive'] != null) {
          final subscriptionActive = data['subscriptionActive'] as bool?;
          if (subscriptionActive != filters['subscriptionActive']) {
            passesFilters = false;
          }
        }

        if (passesFilters) {
          providers.add(ProviderModel.fromFirestore(data, providerDoc.id));
        }
      }

      return providers;
    } catch (e) {
      print('Error in searchProvidersByCategoryWithFilters: $e');
      return [];
    }
  }

  /// Get available categories from services
  Future<Map<String, List<String>>> getAvailableCategories() async {
    try {
      return await _categoriesService.getCategoriesForFilter();
    } catch (e) {
      print('Error getting available categories: $e');
      return {};
    }
  }

  /// Get available wilayas from providers
  Future<List<String>> getAvailableWilayas() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('wilaya', isNotEqualTo: null)
          .get();

      final wilayas = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final wilaya = data['wilaya'] as String?;
        if (wilaya != null && wilaya.isNotEmpty) {
          wilayas.add(wilaya);
        }
      }

      return wilayas.toList()..sort();
    } catch (e) {
      print('Error getting available wilayas: $e');
      return [];
    }
  }

  /// Get services by provider ID
  Future<List<Service>> getServicesByProvider(String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Service.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting services by provider: $e');
      return [];
    }
  }

  /// Calculate distance between two coordinates
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180);
}
