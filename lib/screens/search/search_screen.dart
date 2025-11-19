import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- YOUR APP IMPORTS ---
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/screens/profile/provider_profile.dart';
// Assumed to define colors/styles
import 'package:myapp/screens/search/search_map_delegate.dart'; // Assumed to define CustomServiceSearchDelegate

// --- CONSTANTS (Pulled from search_constants.dart for immediate use) ---
const Color kCardBackgroundColor = Colors.white;
const Color kLightBackgroundColor = Color(0xFFF8F9FF);
const Color kDarkTextColor = Color(0xFF323232);
const Color kMutedTextColor = Color(0xFF969696);
// --- END CONSTANTS ---

// 💡 DUMMY DATA REMOVED: Data fetching will now happen via Firebase Firestore.

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  late GoogleMapController _mapController;
  late BitmapDescriptor _customMarkerIcon;
  bool _isLoading = true;

  // Set the initial position (e.g., Cairo)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 12,
  );

  Set<Marker> _markers = {};
  // The selectedFilters map is not used in the map display logic yet but kept.
  final Map<String, String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _initializeMapAssets();
    // 💡 Start fetching providers immediately after initializing assets
    _fetchProvidersFromFirebase();
  }

  Future<void> _initializeMapAssets() async {
    // 1. Load the custom icon first (asynchronously)
    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/1.png',
    );
    _customMarkerIcon = icon;

    // 💡 REMOVED: Removed the dummy data loading call from here.
  }

  // --- NEW: FETCHING LOGIC WITH FIREBASE FILTER ---
  Future<void> _fetchProvidersFromFirebase() async {
    // We assume the collection is 'users' and providers are identified by role.
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'provider') // <-- KEY FILTER
              .get();

      final List<ProviderModel> fetchedProviders =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Ensure you safely map GeoPoint and other fields
            final GeoPoint? location = data['location'] as GeoPoint?;

            // NOTE: You must ensure your ProviderModel constructor handles all these fields.
            return ProviderModel(
              uid: doc.id,
              name: data['name'] ?? 'No Name',
              profession: data['profession'] ?? 'Service Provider',
              description: data['description'] ?? '',
              phone: data['phone'] ?? '',
              whatsapp: data['whatsapp'] ?? '',
              address: data['address'] ?? 'Unknown location',
              rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
              subscriptionActive: data['subscriptionActive'] ?? false,
              userRef: doc.reference,
              services:
                  data['services'] is List
                      ? List<String>.from(data['services'])
                      : [],
              location: location,
            );
          }).toList();

      // Load markers onto the map using the filtered list
      _loadMarkers(fetchedProviders);
    } catch (e) {
      print("Error fetching providers: $e");
    } finally {
      // Mark loading as complete regardless of success or failure
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- END NEW LOGIC ---

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
