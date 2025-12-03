import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ViewModel/search_view_model.dart';
import 'package:myapp/screens/profile/provider_profile/provider_profile_widget.dart';
import 'package:myapp/screens/search/search_filter_dialog.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/services/wilaya_service.dart';
import 'package:myapp/services/categories_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/geocoding_service.dart';

// Colors (define these or import from your constants)
const Color kPrimaryBlue = Color(0xFF2196F3);
const Color kMutedTextColor = Color(0xFF666666);
const Color kDarkTextColor = Color(0xFF333333);
const Color kLightBackgroundColor = Color(0xFFF8F9FA);
const Color kCardBackgroundColor = Colors.white;

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  late GoogleMapController _mapController;
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _markerCache = {};

  // ViewModel
  late SearchViewModel _searchViewModel;

  // Services
  final CategoriesService _categoriesService = CategoriesService();
  final LocationService _locationService = LocationService();

  // Current filters
  Map<String, dynamic> _currentFilters = {};
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  List<String> _wilayas = [];
  Map<String, List<String>> _categoriesWithSubcategories = {};

  @override
  void initState() {
    super.initState();
    _searchViewModel = SearchViewModel();
    _initializeMap();
    _loadInitialData();
  }

  @override
  void dispose() {
    _clearResources();
    super.dispose();
  }

  void _clearResources() {
    // Clear markers
    _markers.clear();
    _markerCache.clear();

    // Dispose map controller safely
    try {
      _mapController.dispose();
    } catch (e) {
      print('Error clearing map resources: $e');
    }
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      // Get user's current location
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _userLocation = LatLng(position.latitude, position.longitude);

        setState(() {
          _initialCameraPosition = CameraPosition(
            target: _userLocation!,
            zoom: 12,
          );
        });
      } else {
        // Fallback to Algiers coordinates
        setState(() {
          _initialCameraPosition = const CameraPosition(
            target: LatLng(36.7525, 3.0420),
            zoom: 12,
          );
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      // Fallback to Algiers coordinates
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(36.7525, 3.0420),
          zoom: 12,
        );
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Load wilayas
      _wilayas = WilayaService.getAllWilayaNames();

      // Load categories
      _categoriesWithSubcategories = await _categoriesService
          .getCategoriesForFilter();

      // Load initial providers
      await _searchProvidersWithCurrentFilters();
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> _searchProvidersWithCurrentFilters() async {
    try {
      setState(() {
        _searchViewModel.clearResults();
        _markers.clear();
      });

      await _searchViewModel.searchWithFilters(_currentFilters);

      // Check if we have providers
      if (_searchViewModel.providerResults.isEmpty) {
        // No providers found - center on selected location if available
        _centerMapOnSelectedLocation();
      } else {
        // We have providers - create markers
        await _createMarkersFromProviders(_searchViewModel.providerResults);
      }
    } catch (e) {
      print('Error searching providers: $e');
      // Still try to center on location even if there's an error
      _centerMapOnSelectedLocation();
    }
  }

  Future<void> _createMarkersFromProviders(
    List<ProviderModel> providers,
  ) async {
    final Set<Marker> newMarkers = {};

    for (var provider in providers) {
      if (provider.location == null) continue;

      final marker = Marker(
        markerId: MarkerId(
          provider.uid ??
              '${provider.name}_${DateTime.now().millisecondsSinceEpoch}',
        ),
        position: provider.location!,
        infoWindow: InfoWindow(
          title: provider.name,
          snippet: '${provider.profession} • ${provider.wilaya}',
          onTap: () => _handleMarkerTap(provider),
        ),
        // Use enhanced marker for better visibility
        icon: await _createEnhancedMarkerIcon(provider),
        // Optional: Add z-index for better visibility
        zIndex: 1,
        // Optional: Add anchor point
        anchor: const Offset(0.5, 0.5),
        onTap: () => _handleMarkerTap(provider),
      );

      newMarkers.add(marker);
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  Future<BitmapDescriptor> _createEnhancedMarkerIcon(
    ProviderModel provider,
  ) async {
    try {
      const double markerSize = 64.0; // Even larger for maximum visibility

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      // Draw colored circle with white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      final innerPaint = Paint()
        ..color = _getProfessionColor(provider.profession)
        ..style = PaintingStyle.fill;

      // Draw main circle
      canvas.drawCircle(
        Offset(markerSize / 2, markerSize / 2),
        markerSize / 2 - 2,
        innerPaint,
      );

      canvas.drawCircle(
        Offset(markerSize / 2, markerSize / 2),
        markerSize / 2 - 2,
        borderPaint,
      );

      // Add profession initial
      final textPainter = TextPainter(
        text: TextSpan(
          text: _getProfessionInitial(provider.profession),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Exo2',
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          markerSize / 2 - textPainter.width / 2,
          markerSize / 2 - textPainter.height / 2,
        ),
      );

      // Add a small white dot in center for extra clarity
      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(markerSize / 2, markerSize / 2), 3, dotPaint);

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(
        markerSize.toInt(),
        markerSize.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final markerIcon = BitmapDescriptor.fromBytes(buffer);

      // Cache the marker
      final cacheKey = '${provider.uid}_${provider.profession}';
      _markerCache[cacheKey] = markerIcon;

      return markerIcon;
    } catch (e) {
      print('Error creating enhanced marker: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  void _applyFilters(Map<String, dynamic> filters) async {
    setState(() {
      _currentFilters = filters;
      _markers.clear();
      _markerCache.clear();
    });

    // Handle distance filter
    if (filters['useDistanceFilter'] == true && _userLocation != null) {
      _currentFilters['userLat'] = _userLocation!.latitude;
      _currentFilters['userLng'] = _userLocation!.longitude;
      _currentFilters['maxDistanceKm'] = filters['maxDistance'] ?? 20.0;
    }

    await _searchProvidersWithCurrentFilters();
  }

  void _centerMapOnSelectedLocation() {
    // Try to get wilaya coordinates from filters
    final wilayaCoordinates = _currentFilters['wilayaCoordinates'] as LatLng?;
    final wilayaName = _currentFilters['wilaya'] as String?;

    // If we have coordinates in filters, use them
    if (wilayaCoordinates != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(wilayaCoordinates, 12),
      );
      _showNoProvidersMessage(wilayaName ?? 'cette région');
    }
    // If we have a wilaya name but no coordinates, try to get them
    else if (wilayaName != null) {
      _getAndCenterWilaya(wilayaName);
    }
    // If we have user location, center on it
    else if (_userLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 12),
      );
    }
  }

  Future<void> _getAndCenterWilaya(String wilayaName) async {
    try {
      final coordinates = await GeocodingService.getWilayaCoordinates(
        wilayaName,
      );
      if (coordinates != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(coordinates, 12),
        );
        _showNoProvidersMessage(wilayaName);
      } else {
        // If no coordinates found, show a message
        _showNoCoordinatesMessage(wilayaName);
      }
    } catch (e) {
      print('Error getting coordinates for $wilayaName: $e');
      _showNoCoordinatesMessage(wilayaName);
    }
  }

  void _showNoProvidersMessage(String locationName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Aucun prestataire trouvé pour $locationName avec ces critères',
          style: TextStyle(fontFamily: 'Exo2'),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showNoCoordinatesMessage(String locationName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Impossible de localiser $locationName',
          style: TextStyle(fontFamily: 'Exo2'),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
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

  void _handleMarkerTap(ProviderModel provider) {
    // Show a custom info sheet
    _showProviderInfoSheet(provider);
  }

  void _showProviderInfoSheet(ProviderModel provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildProviderInfoSheet(provider),
    );
  }

  Widget _buildProviderInfoSheet(ProviderModel provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with colored profession indicator
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _getProfessionColor(provider.profession),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Profession icon circle
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getProfessionColor(provider.profession),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          _getProfessionInitial(provider.profession),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Exo2',
                              color: kDarkTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.profession,
                            style: TextStyle(
                              fontSize: 16,
                              color: _getProfessionColor(provider.profession),
                              fontFamily: 'Exo2',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (provider.rating > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  provider.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (provider.subscriptionActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kPrimaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Vérifié',
                                      style: TextStyle(
                                        color: kPrimaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                if (provider.wilaya.isNotEmpty || provider.commune.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kLightBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: kMutedTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Localisation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kMutedTextColor,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${provider.commune.isNotEmpty ? "${provider.commune}, " : ""}${provider.wilaya}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Exo2',
                                  color: kDarkTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Description if available
                if (provider.description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kLightBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 12,
                            color: kMutedTextColor,
                            fontFamily: 'Exo2',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.description,
                          style: TextStyle(
                            color: kDarkTextColor,
                            fontSize: 14,
                            fontFamily: 'Exo2',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Chat Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _startChatWithProvider(provider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chat,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Envoyer un message',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Exo2',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // View Profile Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProviderProfileScreen(
                                provider: provider,
                                serviceCategory: provider.profession,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: kPrimaryBlue, width: 1),
                          ),
                        ),
                        icon: Icon(Icons.person, color: kPrimaryBlue, size: 20),
                        label: Text(
                          'Voir le profil',
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontFamily: 'Exo2',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Close Button
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: kMutedTextColor.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Fermer',
                        style: TextStyle(fontFamily: 'Exo2', fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startChatWithProvider(ProviderModel provider) {
    // TODO: Implement chat functionality
    print('Starting chat with: ${provider.name}');

    // Show a temporary message since chat functionality is not implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Fonctionnalité de chat à venir avec ${provider.name}',
          style: TextStyle(fontFamily: 'Exo2'),
        ),
        backgroundColor: kPrimaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getProfessionColor(String profession) {
    final lowerProfession = profession.toLowerCase();

    if (lowerProfession.contains('électr') ||
        lowerProfession.contains('electric')) {
      return Colors.amber.shade700;
    } else if (lowerProfession.contains('médec') ||
        lowerProfession.contains('doctor')) {
      return Colors.red;
    } else if (lowerProfession.contains('plomb') ||
        lowerProfession.contains('plumb')) {
      return Colors.blue;
    } else if (lowerProfession.contains('profess') ||
        lowerProfession.contains('teacher') ||
        lowerProfession.contains('tutor')) {
      return Colors.green;
    } else if (lowerProfession.contains('menuis') ||
        lowerProfession.contains('carpent')) {
      return Colors.brown;
    } else if (lowerProfession.contains('peint') ||
        lowerProfession.contains('paint')) {
      return Colors.purple;
    } else if (lowerProfession.contains('jardin') ||
        lowerProfession.contains('garden')) {
      return Colors.lightGreen;
    } else if (lowerProfession.contains('déménag') ||
        lowerProfession.contains('move')) {
      return Colors.deepOrange;
    } else if (lowerProfession.contains('nettoy') ||
        lowerProfession.contains('clean')) {
      return Colors.lightBlue;
    } else if (lowerProfession.contains('répar') ||
        lowerProfession.contains('repair') ||
        lowerProfession.contains('handyman')) {
      return Colors.orange;
    } else if (lowerProfession.contains('install')) {
      return Colors.cyan;
    }

    return kPrimaryBlue;
  }

  String _getProfessionInitial(String profession) {
    if (profession.isEmpty) return "?";
    return profession.substring(0, 1).toUpperCase();
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

  void _clearFilters() {
    setState(() {
      _currentFilters = {};
      _markers.clear();
      _markerCache.clear();
    });

    // Reload with no filters
    _searchProvidersWithCurrentFilters();
  }

  void _centerMapOnUser() {
    if (_userLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 14),
      );
    }
  }

  void _centerMapOnMarkers() {
    if (_markers.isNotEmpty) {
      final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double? minLat, maxLat, minLng, maxLng;

    for (var pos in positions) {
      minLat = minLat != null
          ? (pos.latitude < minLat ? pos.latitude : minLat)
          : pos.latitude;
      maxLat = maxLat != null
          ? (pos.latitude > maxLat ? pos.latitude : maxLat)
          : pos.latitude;
      minLng = minLng != null
          ? (pos.longitude < minLng ? pos.longitude : minLng)
          : pos.longitude;
      maxLng = maxLng != null
          ? (pos.longitude > maxLng ? pos.longitude : maxLng)
          : pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Clear resources before navigating back
        _clearResources();
        return true;
      },
      child: ChangeNotifierProvider.value(
        value: _searchViewModel,
        child: Scaffold(
          // Add a background color to prevent black screen
          backgroundColor: Colors.white,
          body: SafeArea(
            // Wrap with SafeArea to handle notches and system UI
            top: false, // We'll handle top manually in search bar
            child: Stack(
              children: [
                // Google Map
                SizedBox.expand(
                  child: _isLoadingLocation || _initialCameraPosition == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: kPrimaryBlue),
                              const SizedBox(height: 16),
                              Text(
                                _isLoadingLocation
                                    ? "Chargement de la position..."
                                    : "Chargement de la carte...",
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
                          },
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: false,
                          compassEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                ),

                // Search/Filter Bar with working back button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildSearchBar(context),
                ),

                // Loading overlay
                Consumer<SearchViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryBlue,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Map Controls
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        onPressed: _centerMapOnUser,
                        backgroundColor: kCardBackgroundColor,
                        child: Icon(
                          Icons.my_location,
                          color: kPrimaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_markers.isNotEmpty)
                        FloatingActionButton.small(
                          onPressed: _centerMapOnMarkers,
                          backgroundColor: kCardBackgroundColor,
                          child: Icon(
                            Icons.zoom_out_map,
                            color: kPrimaryBlue,
                            size: 20,
                          ),
                        ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: () {
                          _mapController.animateCamera(CameraUpdate.zoomIn());
                        },
                        backgroundColor: kCardBackgroundColor,
                        child: Icon(Icons.add, color: kPrimaryBlue, size: 20),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: () {
                          _mapController.animateCamera(CameraUpdate.zoomOut());
                        },
                        backgroundColor: kCardBackgroundColor,
                        child: Icon(
                          Icons.remove,
                          color: kPrimaryBlue,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Error message
                Consumer<SearchViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.error != null &&
                        viewModel.error!.isNotEmpty) {
                      return Positioned(
                        top: 100,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  viewModel.error!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Exo2',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => viewModel.clearError(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Results counter
                if (_markers.isNotEmpty)
                  Positioned(
                    top: 120,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kCardBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pin_drop, color: kPrimaryBlue, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${_markers.length} prestataires',
                            style: TextStyle(
                              color: kDarkTextColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Exo2',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 10, 16, 10),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button - FIXED AND SIMPLE
          IconButton(
            onPressed: () {
              // Clear map resources first
              _clearResources();

              // Then navigate back
              Navigator.of(context).pop();
            },
            icon: Icon(CupertinoIcons.back, color: kDarkTextColor, size: 24),
          ),
          const SizedBox(width: 8),

          // Search/Filters Button
          Expanded(
            child: GestureDetector(
              onTap: _showFilterDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kLightBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kMutedTextColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      color: kMutedTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<SearchViewModel>(
                        builder: (context, viewModel, child) {
                          return Text(
                            _buildSearchHint(),
                            style: TextStyle(
                              color: kMutedTextColor,
                              fontSize: 15,
                              fontFamily: 'Exo2',
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    if (_currentFilters.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
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
          const SizedBox(width: 8),
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
