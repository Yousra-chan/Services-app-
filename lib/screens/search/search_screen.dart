import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- YOUR APP IMPORTS ---
import 'package:myapp/Models/ProviderModel.dart';
import 'package:myapp/screens/profile/provider_profile.dart';
// Assumed to define colors/styles
import 'package:myapp/screens/search/search_map_delegate.dart'; // Assumed to define CustomServiceSearchDelegate

// --- DUMMY DATA (REQUIRED FOR MARKER CREATION) ---
// Note: These need a valid GeoPoint and UID for marker creation.
final List<ProviderModel> _dummyProvidersList = [
  ProviderModel(
    uid: 'p001',
    name: 'Dr. Hiba',
    profession: 'Physiotherapist',
    description: 'Specializes in sports injuries.',
    phone: '...',
    whatsapp: '...',
    address: 'Cairo Center',
    rating: 4.9,
    subscriptionActive: true,
    userRef: FirebaseFirestore.instance.doc('users/hba'),
    services: const [],
    location: const GeoPoint(
      30.05,
      31.20,
    ), // Matches one of the original LatLngs
  ),
  ProviderModel(
    uid: 'p002',
    name: 'Khaled Elec.',
    profession: 'Electrician',
    description: 'Certified for residential wiring.',
    phone: '...',
    whatsapp: '...',
    address: 'Giza East',
    rating: 4.5,
    subscriptionActive: true,
    userRef: FirebaseFirestore.instance.doc('users/khaled'),
    services: const [],
    location: const GeoPoint(
      30.03,
      31.25,
    ), // Matches one of the original LatLngs
  ),
  // Add more dummy providers here, ensuring their GeoPoint matches the map's area (30.04, 31.23)
];

// Assuming kCardBackgroundColor, kLightBackgroundColor, kDarkTextColor, kMutedTextColor are defined in search_constants.dart
const Color kCardBackgroundColor = Colors.white;
const Color kLightBackgroundColor = Color(0xFFF8F9FF);
const Color kDarkTextColor = Color(0xFF323232);
const Color kMutedTextColor = Color(0xFF969696);
// --- END DUMMY DATA ---

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  late GoogleMapController _mapController;
  late BitmapDescriptor _customMarkerIcon;
  bool _isLoading = true;

  // Set the initial position to be close to the dummy marker data (Cairo)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 12,
  );

  Set<Marker> _markers = {};
  final Map<String, String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _initializeMapAssets();
  }

  Future<void> _initializeMapAssets() async {
    // 1. Load the custom icon first (asynchronously)
    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/1.png',
    );
    _customMarkerIcon = icon;

    // --- FIX APPLIED HERE ---
    // 2. Call the real _loadMarkers function using the dummy data.
    // NOTE: In a real app, this list would come from a Firestore fetch result.
    _loadMarkers(_dummyProvidersList);
    // -------------------------

    // 3. Mark loading as complete and trigger a rebuild to show the map
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to convert data to actual Google Maps Markers
  void _loadMarkers(List<ProviderModel> availableProviders) {
    final Set<Marker> markers = {};

    for (var provider in availableProviders) {
      // Check if the location is valid before creating a marker
      if (provider.location != null) {
        // Convert Firestore GeoPoint to Google Maps LatLng
        final LatLng position = LatLng(
          provider.location!.latitude,
          provider.location!.longitude,
        );

        markers.add(
          Marker(
            markerId: MarkerId(provider.uid!),
            position: position,
            infoWindow: InfoWindow(
              title: provider.name,
              snippet: provider.profession,
            ),
            icon: _customMarkerIcon, // The loaded icon is now available
            onTap: () => _handleMarkerTap(provider),
          ),
        );
      }
    }

    // Assign the new set of markers (this will trigger a map rebuild via setState)
    setState(() {
      _markers = markers;
    });
  }

  void _handleMarkerTap(ProviderModel provider) {
    // Use Navigator to push the ProviderProfilePage when a marker is tapped.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderProfilePage(provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Show loader while assets load
                    : GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: _initialCameraPosition,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      markers: _markers, // Displaying the loaded markers
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                      padding: const EdgeInsets.only(bottom: 100.0),
                    ),
          ),

          // 2. Overlaid Search/Filter Bar at the Top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildSearchBar(context),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Custom Search Bar/Header
  Widget _buildSearchBar(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 10),
      decoration: const BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              CupertinoIcons.back,
              color: kDarkTextColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),

          // Search Bar (tap to open delegate)
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await showSearch<String>(
                  context: context,
                  delegate: CustomServiceSearchDelegate(),
                );

                if (result != null && result.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Search triggered for: $result"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kLightBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      color: kMutedTextColor,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Service or Address...",
                      style: TextStyle(
                        color: kMutedTextColor,
                        fontSize: 16,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
