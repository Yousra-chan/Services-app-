import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ProviderModel.dart';
import '../models/ServicesModel.dart';
import 'location_service.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // ============ PROVIDER SEARCH METHODS ============

  // Search providers near user location
  Future<List<ProviderModel>> searchProvidersNearby({
    double radiusInMeters = 10000, // 10 km default radius
    int limit = 20,
  }) async {
    try {
      // Get user's current location
      final Position? userLocation =
          await _locationService.getCurrentLocation();
      if (userLocation == null) {
        throw Exception('Unable to get user location');
      }

      print(
          'Searching providers near: ${userLocation.latitude}, ${userLocation.longitude}');

      // Get all providers with active subscription
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .get();

      // Filter providers by distance
      final nearbyProviders = <ProviderModel>[];

      for (var doc in snapshot.docs) {
        try {
          final provider = ProviderModel.fromMap(doc.data(), doc.id);

          // Check if provider has location data
          if (provider.location != null) {
            final distance = _locationService.calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              provider.location!.latitude,
              provider.location!.longitude,
            );

            // Add provider if within radius
            if (distance <= radiusInMeters) {
              nearbyProviders.add(provider);
            }
          }
        } catch (e) {
          print('Error parsing provider ${doc.id}: $e');
        }
      }

      // Sort by distance (closest first)
      nearbyProviders.sort((a, b) {
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

      final results = nearbyProviders.take(limit).toList();
      print('Found ${results.length} nearby providers');
      return results;
    } catch (e) {
      print('Error searching nearby providers: $e');
      return [];
    }
  }

  // Enhanced search that includes location-based sorting
  Future<List<ProviderModel>> searchProvidersByProfessionOrName(
    String query, {
    bool sortByDistance = true,
  }) async {
    if (query.isEmpty) {
      // If no query, return nearby providers
      return await searchProvidersNearby();
    }

    final lowerCaseQuery = query.toLowerCase();
    final endQuery = '$lowerCaseQuery\uf8ff';

    try {
      // Search by profession
      final professionQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .where('profession', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('profession', isLessThanOrEqualTo: endQuery);

      // Search by name
      final nameQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('name', isLessThanOrEqualTo: endQuery);

      final snapshotByProfession = await professionQuery.get();
      final snapshotByName = await nameQuery.get();

      final allDocs = [...snapshotByProfession.docs, ...snapshotByName.docs];

      // Remove duplicates
      final uniqueProvidersMap = <String, ProviderModel>{};
      for (var doc in allDocs) {
        try {
          final provider = ProviderModel.fromMap(doc.data(), doc.id);
          uniqueProvidersMap[doc.id] = provider;
        } catch (e) {
          print('Error parsing provider ${doc.id}: $e');
        }
      }

      var results = uniqueProvidersMap.values.toList();

      // If we have user location, sort results by distance
      if (sortByDistance) {
        final userLocation = await _locationService.getCurrentLocation();
        if (userLocation != null) {
          results = _sortProvidersByDistance(results, userLocation);
        }
      }

      return results;
    } catch (e) {
      print('Error searching providers: $e');
      return [];
    }
  }

  // ============ SERVICE SEARCH METHODS ============

  // Search services by title, category, or description
  Future<List<Service>> searchServices(
    String query, {
    bool sortByDistance = true,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      final lowercaseQuery = query.toLowerCase();

      // Get all active services
      final querySnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter locally for better search across multiple fields
      var results = querySnapshot.docs
          .map((doc) => Service.fromMap(doc.data()))
          .where((service) =>
              service.title.toLowerCase().contains(lowercaseQuery) ||
              service.category.toLowerCase().contains(lowercaseQuery) ||
              service.description.toLowerCase().contains(lowercaseQuery) ||
              service.tags
                  .any((tag) => tag.toLowerCase().contains(lowercaseQuery)))
          .toList();

      // Sort by distance if requested
      if (sortByDistance) {
        final userLocation = await _locationService.getCurrentLocation();
        if (userLocation != null) {
          results = _sortServicesByDistance(results, userLocation);
        }
      }

      return results;
    } catch (e) {
      print('Error searching services: $e');
      throw Exception('Failed to search services: $e');
    }
  }

  // Search services by category only
  Future<List<Service>> searchServicesByCategory(
    String category, {
    bool sortByDistance = true,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      var results =
          querySnapshot.docs.map((doc) => Service.fromMap(doc.data())).toList();

      // Sort by distance if requested
      if (sortByDistance) {
        final userLocation = await _locationService.getCurrentLocation();
        if (userLocation != null) {
          results = _sortServicesByDistance(results, userLocation);
        }
      }

      return results;
    } catch (e) {
      print('Error searching services by category: $e');
      throw Exception('Failed to search services by category: $e');
    }
  }

  // Search services by location
  Future<List<Service>> searchServicesByLocation(
    String location, {
    bool sortByDistance = true,
  }) async {
    try {
      final lowercaseLocation = location.toLowerCase();

      final querySnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter locally for partial location matching
      var results = querySnapshot.docs
          .map((doc) => Service.fromMap(doc.data()))
          .where((service) =>
              service.location.toLowerCase().contains(lowercaseLocation))
          .toList();

      // Sort by distance if requested
      if (sortByDistance) {
        final userLocation = await _locationService.getCurrentLocation();
        if (userLocation != null) {
          results = _sortServicesByDistance(results, userLocation);
        }
      }

      return results;
    } catch (e) {
      print('Error searching services by location: $e');
      throw Exception('Failed to search services by location: $e');
    }
  }

  // Get featured services (for homepage)
  Future<List<Service>> getFeaturedServices({
    bool sortByDistance = true,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      var results =
          querySnapshot.docs.map((doc) => Service.fromMap(doc.data())).toList();

      // Sort by rating first
      results.sort((a, b) => b.rating.compareTo(a.rating));

      // Then by distance if requested
      if (sortByDistance) {
        final userLocation = await _locationService.getCurrentLocation();
        if (userLocation != null) {
          results = _sortServicesByDistance(results, userLocation);
        }
      }

      return results;
    } catch (e) {
      print('Error getting featured services: $e');
      throw Exception('Failed to get featured services: $e');
    }
  }

  // ============ HELPER METHODS ============

  // Sort providers by distance from user location
  List<ProviderModel> _sortProvidersByDistance(
    List<ProviderModel> providers,
    Position userLocation,
  ) {
    return providers
      ..sort((a, b) {
        // Providers with location data come first
        if (a.location == null && b.location == null) return 0;
        if (a.location == null) return 1;
        if (b.location == null) return -1;

        // Calculate distances
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

  // Sort services by distance from user location
  List<Service> _sortServicesByDistance(
    List<Service> services,
    Position userLocation,
  ) {
    return services
      ..sort((a, b) {
        // Services with location data come first
        if (a.latitude == null && b.latitude == null) return 0;
        if (a.latitude == null) return 1;
        if (b.latitude == null) return -1;

        // Calculate distances
        final distanceA = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distanceB = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          b.latitude!,
          b.longitude!,
        );

        return distanceA.compareTo(distanceB);
      });
  }

  // Get distance between user and provider
  Future<double?> getDistanceToProvider(ProviderModel provider) async {
    try {
      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation == null || provider.location == null) {
        return null;
      }

      return _locationService.calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        provider.location!.latitude,
        provider.location!.longitude,
      );
    } catch (e) {
      print('Error calculating distance to provider: $e');
      return null;
    }
  }

  // Get distance between user and service
  Future<double?> getDistanceToService(Service service) async {
    try {
      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation == null || service.latitude == null) {
        return null;
      }

      return _locationService.calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        service.latitude!,
        service.longitude!,
      );
    } catch (e) {
      print('Error calculating distance to service: $e');
      return null;
    }
  }

  // Convert meters to kilometers for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Get services by provider ID
  Future<List<Service>> getServicesByProvider(String providerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Service.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting services by provider: $e');
      throw Exception('Failed to get services by provider: $e');
    }
  }
}
