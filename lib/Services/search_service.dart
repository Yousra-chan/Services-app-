import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/models/ServicesModel.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // Helper method to extract wilaya from address
  String? _extractWilayaFromAddress(String address) {
    if (address.isEmpty) return null;

    // Try to find wilaya in address (common patterns)
    final wilayas = [
      'Alger',
      'Boumerdès',
      'Blida',
      'Oran',
      'Tizi Ouzou',
      'Constantine'
    ];

    for (var wilaya in wilayas) {
      if (address.toLowerCase().contains(wilaya.toLowerCase())) {
        return wilaya;
      }
    }

    return null;
  }

  // Helper method to extract commune from address
  String? _extractCommuneFromAddress(String address) {
    if (address.isEmpty) return null;

    // Return first part of address (usually commune)
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }

    return null;
  }

  // CORRECTED - Search with filters for YOUR data structure
  Future<List<ProviderModel>> searchProvidersWithFilters(
    Map<String, dynamic> filters, {
    int limit = 50,
  }) async {
    print('\n🔍 === STARTING FILTERED SEARCH ===');
    print('Filters: $filters');

    try {
      final String? wilayaFilter = filters['wilaya'];
      final String? communeFilter = filters['commune'];
      final String? categoryFilter = filters['category'];
      final String? subcategoryFilter = filters['subcategory'];
      final double? maxDistance = filters['maxDistance'];
      final bool useDistanceFilter = filters['useDistanceFilter'] ?? false;

      // Step 1: Get all active providers from users collection
      final providersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .get();

      print('📥 Found ${providersSnapshot.docs.length} active providers');

      List<ProviderModel> allProviders = [];

      // Convert all provider documents
      for (var providerDoc in providersSnapshot.docs) {
        try {
          final providerData = providerDoc.data();

          // Debug print - FIXED: Changed to proper Dart syntax
          print(
              '👤 Provider ${providerDoc.id}: name=${providerData['name']}, address=${providerData['address']}, profession=${providerData['profession']}');

          final user = UserModel.fromMap(providerData, providerDoc.id);
          allProviders.add(ProviderModel.fromUser(user));
        } catch (e) {
          print('❌ Error creating provider ${providerDoc.id}: $e');
        }
      }

      // Step 2: Get all services to check category/subcategory
      Map<String, List<Map<String, dynamic>>> providerServicesMap = {};

      if (categoryFilter != null || subcategoryFilter != null) {
        final servicesSnapshot = await _firestore
            .collection('services')
            .where('isActive', isEqualTo: true)
            .get();

        // Group services by providerId
        for (var serviceDoc in servicesSnapshot.docs) {
          final serviceData = serviceDoc.data();
          final providerId = serviceData['providerId'] as String?;

          if (providerId != null) {
            providerServicesMap[providerId] ??= [];
            providerServicesMap[providerId]!.add(serviceData);
          }
        }
      }

      // Step 3: Apply filters
      List<ProviderModel> filteredProviders = [];

      for (var provider in allProviders) {
        bool passesFilters = true;

        // Apply wilaya filter (extract from address)
        if (wilayaFilter != null &&
            wilayaFilter.isNotEmpty &&
            wilayaFilter != 'null') {
          final providerWilaya = _extractWilayaFromAddress(provider.address);
          if (providerWilaya == null ||
              !providerWilaya
                  .toLowerCase()
                  .contains(wilayaFilter.toLowerCase())) {
            passesFilters = false;
            // FIXED: Changed to proper Dart string interpolation
            print(
                '   ❌ ${provider.name} doesn\'t match wilaya filter: $providerWilaya != $wilayaFilter');
          }
        }

        // Apply commune filter (extract from address)
        if (communeFilter != null &&
            communeFilter.isNotEmpty &&
            communeFilter != 'null' &&
            passesFilters) {
          final providerCommune = _extractCommuneFromAddress(provider.address);
          if (providerCommune == null ||
              !providerCommune
                  .toLowerCase()
                  .contains(communeFilter.toLowerCase())) {
            passesFilters = false;
            // FIXED: Changed to proper Dart string interpolation
            print(
                '   ❌ ${provider.name} doesn\'t match commune filter: $providerCommune != $communeFilter');
          }
        }

        // Apply category/subcategory filter
        if ((categoryFilter != null &&
                categoryFilter.isNotEmpty &&
                categoryFilter != 'null') ||
            (subcategoryFilter != null &&
                subcategoryFilter.isNotEmpty &&
                subcategoryFilter != 'null')) {
          final providerServices =
              providerServicesMap[provider.uid ?? ''] ?? [];

          if (providerServices.isEmpty) {
            // Provider has no services, check profession
            if (categoryFilter != null &&
                !provider.profession
                    .toLowerCase()
                    .contains(categoryFilter.toLowerCase())) {
              passesFilters = false;
              // FIXED: Changed to proper Dart string interpolation
              print(
                  '   ❌ ${provider.name} has no services and profession doesn\'t match: ${provider.profession}');
            }
          } else {
            bool hasMatchingService = false;

            for (var service in providerServices) {
              bool matchesCategory = true;
              bool matchesSubcategory = true;

              // Check category
              if (categoryFilter != null &&
                  categoryFilter.isNotEmpty &&
                  categoryFilter != 'null') {
                final serviceCategory =
                    (service['category'] as String? ?? '').toLowerCase();
                matchesCategory =
                    serviceCategory.contains(categoryFilter.toLowerCase());
              }

              // Check subcategory
              if (subcategoryFilter != null &&
                  subcategoryFilter.isNotEmpty &&
                  subcategoryFilter != 'null') {
                final serviceSubcategory =
                    (service['subcategory'] as String? ?? '').toLowerCase();
                matchesSubcategory = serviceSubcategory
                    .contains(subcategoryFilter.toLowerCase());
              }

              if (matchesCategory && matchesSubcategory) {
                hasMatchingService = true;
                break;
              }
            }

            if (!hasMatchingService) {
              passesFilters = false;
              // FIXED: Changed to proper Dart string interpolation
              print('   ❌ ${provider.name} has no matching services');
            }
          }
        }

        if (passesFilters) {
          filteredProviders.add(provider);
        }
      }

      print('📊 After filtering: ${filteredProviders.length} providers');

      // Apply distance filter
      if (useDistanceFilter && maxDistance != null && maxDistance > 0) {
        filteredProviders = await _filterByDistance(
          filteredProviders,
          maxDistance * 1000,
        );
        // FIXED: Changed to proper Dart string interpolation
        print(
            '📍 After distance filter: ${filteredProviders.length} providers');
      }

      // Sort by distance if user location available
      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation != null) {
        filteredProviders =
            _sortProvidersByDistance(filteredProviders, userLocation);
      }

      final results = filteredProviders.take(limit).toList();
      print('🎉 FINAL RESULTS: ${results.length} providers');

      return results;
    } catch (e) {
      print('❌ ERROR in searchProvidersWithFilters: $e');
      return [];
    }
  }

  // Search providers by name or profession
  Future<List<ProviderModel>> searchProvidersByProfessionOrName(
    String queryText, {
    bool sortByDistance = true,
  }) async {
    if (queryText.isEmpty) {
      return await _getAllActiveProviders();
    }

    final lowerCaseQuery = queryText.toLowerCase();

    try {
      final allProviders = await _getAllActiveProviders();
      final results = <ProviderModel>[];

      for (var provider in allProviders) {
        final providerName = provider.name.toLowerCase();
        final providerProfession = provider.profession.toLowerCase();

        if (providerName.contains(lowerCaseQuery) ||
            providerProfession.contains(lowerCaseQuery)) {
          results.add(provider);
        }
      }

      // Sort by distance if requested
      if (sortByDistance && results.isNotEmpty) {
        final userLocation = await _locationService.getCurrentLocation();
        if (userLocation != null) {
          results.sort((a, b) {
            if (a.location == null && b.location == null) return 0;
            if (a.location == null) return 1;
            if (b.location == null) return -1;

            final distanceA = _locationService.calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              a.location!.latitude,
              a.location!.longitude,
            );
            final distanceB = _locationService.calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              b.location!.latitude,
              b.location!.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
      }

      return results;
    } catch (e) {
      print('Error searching providers: $e');
      return [];
    }
  }

  // Helper to get all active providers
  Future<List<ProviderModel>> _getAllActiveProviders() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final user =
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        return ProviderModel.fromUser(user);
      }).toList();
    } catch (e) {
      print('Error getting all providers: $e');
      return [];
    }
  }

  // ============ FILTER DATA METHODS ============

  Future<Map<String, List<String>>> getAvailableCategories() async {
    try {
      final servicesSnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = <String, List<String>>{};

      for (var doc in servicesSnapshot.docs) {
        final data = doc.data();
        final category = data['category']?.toString() ?? '';
        final subcategory = data['subcategory']?.toString() ?? '';

        if (category.isNotEmpty) {
          if (!categories.containsKey(category)) {
            categories[category] = [];
          }
          if (subcategory.isNotEmpty &&
              !categories[category]!.contains(subcategory)) {
            categories[category]!.add(subcategory);
          }
        }
      }

      // Also add professions from users as categories
      final providers = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .get();

      for (var doc in providers.docs) {
        final data = doc.data();
        final profession = data['profession']?.toString() ?? '';

        if (profession.isNotEmpty && !categories.containsKey(profession)) {
          categories[profession] = [];
        }
      }

      // Sort categories and subcategories
      final sortedKeys = categories.keys.toList()..sort();
      final sortedCategories = <String, List<String>>{};

      for (var key in sortedKeys) {
        final sortedValues = categories[key]!.toList()..sort();
        sortedCategories[key] = sortedValues;
      }

      return sortedCategories;
    } catch (e) {
      print('Error getting categories: $e');
      return {};
    }
  }

  Future<List<String>> getAvailableWilayas() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .get();

      final wilayas = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final address = data['address']?.toString() ?? '';

        if (address.isNotEmpty) {
          final wilaya = _extractWilayaFromAddress(address);
          if (wilaya != null) {
            wilayas.add(wilaya);
          }
        }
      }

      return wilayas.toList()..sort();
    } catch (e) {
      print('Error getting wilayas: $e');
      return [];
    }
  }

  // ============ HELPER METHODS ============

  Future<List<ProviderModel>> _filterByDistance(
    List<ProviderModel> providers,
    double maxDistanceMeters,
  ) async {
    try {
      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation == null) {
        return providers;
      }

      final filtered = <ProviderModel>[];

      for (var provider in providers) {
        if (provider.location == null) continue;

        final distance = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          provider.location!.latitude,
          provider.location!.longitude,
        );

        if (distance <= maxDistanceMeters) {
          filtered.add(provider);
        }
      }

      return filtered;
    } catch (e) {
      print('Error filtering by distance: $e');
      return providers;
    }
  }

  List<ProviderModel> _sortProvidersByDistance(
    List<ProviderModel> providers,
    Position userLocation,
  ) {
    return providers
      ..sort((a, b) {
        if (a.location == null && b.location == null) return 0;
        if (a.location == null) return 1;
        if (b.location == null) return -1;

        final distanceA = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          a.location!.latitude,
          a.location!.longitude,
        );
        final distanceB = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          b.location!.latitude,
          b.location!.longitude,
        );

        return distanceA.compareTo(distanceB);
      });
  }

  // Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // ============ SERVICE SEARCH METHODS ============

  Future<List<Service>> searchServices(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final lowercaseQuery = query.toLowerCase();

      final querySnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      final results = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return Service.fromMap(data);
          })
          .where((service) =>
              service.title.toLowerCase().contains(lowercaseQuery) ||
              service.category.toLowerCase().contains(lowercaseQuery) ||
              service.description.toLowerCase().contains(lowercaseQuery))
          .toList();

      return results;
    } catch (e) {
      print('Error searching services: $e');
      return [];
    }
  }

  Future<List<Service>> searchServicesByCategory(String category) async {
    try {
      if (category.trim().isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      final results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Service.fromMap(data);
      }).toList();

      return results;
    } catch (e) {
      print('Error searching services by category: $e');
      return [];
    }
  }

  Future<List<Service>> getServicesByProvider(String providerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Service.fromMap(data);
      }).toList();

      return results;
    } catch (e) {
      print('Error getting services by provider: $e');
      return [];
    }
  }
}
