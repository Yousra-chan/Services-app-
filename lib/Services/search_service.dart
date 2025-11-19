import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ProviderModel.dart';
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

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
        'Searching providers near: ${userLocation.latitude}, ${userLocation.longitude}',
      );

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
      print('Error calculating distance: $e');
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
}
