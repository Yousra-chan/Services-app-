import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/geocoding_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/search_service.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/screens/profile/provider_profile/provider_profile_page.dart';
import 'package:myapp/screens/search/search_filter_dialog.dart';
import 'package:myapp/screens/search/search_constants.dart'
    hide kMutedTextColor, kDarkTextColor, kPrimaryBlue, kLightBackgroundColor;

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  late GoogleMapController _mapController;
  bool _isLoading = true;
  Map<String, dynamic> _currentFilters = {};
  final SearchService _searchService = SearchService();
  final LocationService _locationService = LocationService();
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = {};
  List<ProviderModel> _currentProviders = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _getUserLocationAndFetchProviders();
  }

  Future<void> _initializeMap() async {
    try {
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      print("Map initialization error: $e");
    }
  }

  Future<void> _getUserLocationAndFetchProviders() async {
    try {
      final Position? userLocation =
          await _locationService.getCurrentLocation();

      if (userLocation != null && mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(userLocation.latitude, userLocation.longitude),
            zoom: 14,
          );
        });
        print(
            "✅ User location set: ${userLocation.latitude}, ${userLocation.longitude}");
      } else {
        // Fallback to Algiers
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(36.7525, 3.0420),
            zoom: 12,
          );
        });
        print("⚠️ Using fallback location (Algiers)");
      }

      // Fetch initial providers
      await _fetchAllProviders();
    } catch (e) {
      print("❌ Error getting user location: $e");
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(36.7525, 3.0420),
          zoom: 12,
        );
      });
      await _fetchAllProviders();
    }
  }

  Future<void> _fetchAllProviders() async {
    try {
      print("🔄 Fetching all providers...");
      setState(() {
        _isLoading = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .get();

      _currentProviders = snapshot.docs.map((doc) {
        final user =
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        return ProviderModel.fromUser(user);
      }).toList();

      print("✅ Found ${_currentProviders.length} providers");

      // Load markers
      await _loadMarkers(_currentProviders);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching providers: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProvidersWithFilters() async {
    try {
      print("🔄 Fetching providers with filters...");
      setState(() {
        _isLoading = true;
      });

      List<ProviderModel> providers;

      if (_currentFilters.isEmpty) {
        providers = _currentProviders;
        print("ℹ️ No filters applied, using all ${providers.length} providers");
      } else {
        providers =
            await _searchService.searchProvidersWithFilters(_currentFilters);
        print("✅ Filter search returned ${providers.length} providers");
      }

      // Clear and load new markers
      await _loadMarkers(providers);

      // Move camera to show results if we have them
      if (providers.isNotEmpty) {
        _zoomToFitMarkers(providers);
      } else {
        _showNoResultsMessage();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching providers with filters: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters(Map<String, dynamic> filters) {
    print("✅ Applying filters: $filters");
    setState(() {
      _currentFilters = filters;
    });
    _fetchProvidersWithFilters();
  }

  void _showNoResultsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Aucun prestataire trouvé avec les filtres sélectionnés"),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );

    // Move back to user location
    _moveToUserLocation();
  }

  Future<void> _moveToUserLocation() async {
    try {
      final Position? userLocation =
          await _locationService.getCurrentLocation();
      if (userLocation != null && _mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(userLocation.latitude, userLocation.longitude),
          ),
        );
      }
    } catch (e) {
      print("❌ Error moving to user location: $e");
    }
  }

  void _zoomToFitMarkers(List<ProviderModel> providers) {
    if (_mapController == null || providers.isEmpty) return;

    try {
      final bounds = _calculateBounds(providers);
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
      print("📍 Zoomed to show ${providers.length} providers");
    } catch (e) {
      print("❌ Error zooming to markers: $e");
    }
  }

  LatLngBounds _calculateBounds(List<ProviderModel> providers) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var provider in providers) {
      if (provider.location != null) {
        final lat = provider.location!.latitude;
        final lng = provider.location!.longitude;

        minLat = lat < minLat ? lat : minLat;
        maxLat = lat > maxLat ? lat : maxLat;
        minLng = lng < minLng ? lng : minLng;
        maxLng = lng > maxLng ? lng : maxLng;
      }
    }

    // If no valid bounds, use default
    if (minLat == double.infinity) {
      return LatLngBounds(
        southwest: LatLng(36.5, 2.8),
        northeast: LatLng(36.9, 3.3),
      );
    }

    // Add padding
    const padding = 0.01;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchFilterDialog(
        onFiltersApplied: _applyFilters,
        initialWilaya: _currentFilters['wilaya'],
        initialCategory: _currentFilters['category'],
        initialSubcategory: _currentFilters['subcategory'],
      ),
    );
  }

  String _buildSearchHint() {
    if (_currentFilters.isEmpty) {
      return "Filtrer par wilaya, catégorie...";
    }

    final wilaya = _currentFilters['wilaya'] ?? '';
    final category = _currentFilters['category'] ?? '';
    final distance = _currentFilters['maxDistance'] ?? 20;

    if (category.isNotEmpty && wilaya.isNotEmpty) {
      return "$category • $wilaya • ${distance.toInt()}km";
    } else if (wilaya.isNotEmpty) {
      return "$wilaya • ${distance.toInt()}km";
    } else if (category.isNotEmpty) {
      return "$category • ${distance.toInt()}km";
    } else {
      return "Filtres actifs • ${distance.toInt()}km";
    }
  }

  Future<void> _loadMarkers(List<ProviderModel> providers) async {
    print("📍 Loading markers for ${providers.length} providers...");

    final Set<Marker> newMarkers = {};
    int markersCreated = 0;

    for (var provider in providers) {
      try {
        LatLng? position;

        // Try to get coordinates
        if (provider.location != null) {
          position = LatLng(
            provider.location!.latitude,
            provider.location!.longitude,
          );
        } else if (provider.wilaya.isNotEmpty) {
          // Fallback: geocode wilaya
          position =
              await GeocodingService.getWilayaCoordinates(provider.wilaya);
        }

        if (position != null) {
          final marker = Marker(
            markerId: MarkerId(provider.uid ?? 'marker_${markersCreated}'),
            position: position,
            infoWindow: InfoWindow(
              title: provider.name,
              snippet: provider.profession,
              onTap: () => _handleMarkerTap(provider),
            ),
            icon: await _createMarkerIcon(provider),
            onTap: () => _handleMarkerTap(provider),
          );

          newMarkers.add(marker);
          markersCreated++;
        } else {
          print("⚠️ Could not get position for ${provider.name}");
        }
      } catch (e) {
        print("❌ Error creating marker for ${provider.name}: $e");
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
      print("✅ Created $markersCreated markers");
    }
  }

  Future<BitmapDescriptor> _createMarkerIcon(ProviderModel provider) async {
    try {
      // Create a simple colored circle marker
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = Size(40, 40);

      // Draw colored circle based on profession
      final paint = Paint()
        ..color = _getProfessionColor(provider.profession)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 2,
        paint,
      );

      // Add white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 2,
        borderPaint,
      );

      // Add profession initial
      final textPainter = TextPainter(
        text: TextSpan(
          text: _getProfessionInitial(provider.profession),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );

      final picture = pictureRecorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(buffer);
    } catch (e) {
      print("❌ Error creating custom marker: $e");
      return BitmapDescriptor.defaultMarker;
    }
  }

  Color _getProfessionColor(String profession) {
    final lowerProfession = profession.toLowerCase();

    if (lowerProfession.contains('plomb')) return Colors.blue;
    if (lowerProfession.contains('électr')) return Colors.amber;
    if (lowerProfession.contains('médec')) return Colors.red;
    if (lowerProfession.contains('profess')) return Colors.green;
    if (lowerProfession.contains('menuis')) return Colors.brown;
    if (lowerProfession.contains('peint')) return Colors.purple;
    if (lowerProfession.contains('jardin')) return Colors.lightGreen;
    if (lowerProfession.contains('déménag')) return Colors.orange;

    return kPrimaryBlue;
  }

  String _getProfessionInitial(String profession) {
    if (profession.isEmpty) return "?";
    return profession.substring(0, 1).toUpperCase();
  }

  void _handleMarkerTap(ProviderModel provider) {
    if (provider.uid != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProviderProfilePage(providerId: provider.uid!),
        ),
      );
    }
  }

  void _clearFilters() {
    print("🗑️ Clearing all filters");
    setState(() {
      _currentFilters = {};
    });
    _fetchAllProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          SizedBox.expand(
            child: _isLoading || _initialCameraPosition == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: kPrimaryBlue),
                        SizedBox(height: 16),
                        Text(
                          "Chargement de la carte...",
                          style: TextStyle(
                            color: kMutedTextColor,
                            fontFamily: 'Exo2',
                          ),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _initialCameraPosition!,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      print("✅ Map controller ready");
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
          ),

          // Search/Filter Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildSearchBar(context),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: kPrimaryBlue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(CupertinoIcons.back, color: kDarkTextColor, size: 24),
          ),
          SizedBox(width: 8),

          // Search/Filters Button
          Expanded(
            child: GestureDetector(
              onTap: _showFilterDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kLightBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kMutedTextColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.search,
                        color: kMutedTextColor, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _buildSearchHint(),
                        style: TextStyle(
                          color: kMutedTextColor,
                          fontSize: 15,
                          fontFamily: 'Exo2',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_currentFilters.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Filter Button
          SizedBox(width: 8),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              CupertinoIcons.slider_horizontal_3,
              color: kDarkTextColor,
              size: 24,
            ),
          ),

          // Clear Filters Button (if filters active)
          if (_currentFilters.isNotEmpty)
            IconButton(
              onPressed: _clearFilters,
              icon: Icon(
                CupertinoIcons.clear,
                color: kMutedTextColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
