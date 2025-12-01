import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSection extends StatefulWidget {
  final Function(String, double?, double?)? onLocationUpdated;

  const LocationSection({
    super.key,
    this.onLocationUpdated,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  bool _isGettingLocation = false;
  Position? _currentPosition;
  Placemark? _currentPlacemark;

  final Color _primaryColor = Color(0xFF2563EB);
  final Color _successColor = Color(0xFF059669);
  final Color _textPrimary = Color(0xFF1E293B);
  final Color _textSecondary = Color(0xFF64748B);
  final Color _borderColor = Color(0xFFE2E8F0);

  // Getters to access location data from parent
  String get address => _locationController.text;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;
  bool get hasLocation => _currentPosition != null;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError('Location services are disabled. Please enable them.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationError('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (!await _checkLocationPermission()) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address = _buildAddressFromPlacemark(placemark);

        setState(() {
          _currentPosition = position;
          _currentPlacemark = placemark;
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
          _locationController.text = address;
        });

        // Notify parent about location update
        widget.onLocationUpdated
            ?.call(address, position.latitude, position.longitude);
      }
    } catch (e) {
      print('Error getting location: $e');
      _showLocationError('Failed to get your current location');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  String _buildAddressFromPlacemark(Placemark placemark) {
    List<String> addressParts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }

    return addressParts.join(', ');
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 20,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your location helps customers find your service',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLocationStatus() {
    IconData statusIcon;
    String statusText;
    String description;
    Color statusColor;

    if (_isGettingLocation) {
      statusIcon = Icons.gps_fixed_rounded;
      statusText = 'Detecting Location';
      description = 'Getting your current position...';
      statusColor = _primaryColor;
    } else if (_currentPosition != null) {
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Location Found';
      description = 'Your location has been detected';
      statusColor = _successColor;
    } else {
      statusIcon = Icons.location_searching_rounded;
      statusText = 'Location Needed';
      description = 'Tap to detect your location';
      statusColor = _textSecondary;
    }

    return GestureDetector(
      onTap: _isGettingLocation ? null : _getCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _isGettingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    )
                  : Icon(
                      statusIcon,
                      size: 20,
                      color: statusColor,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isGettingLocation)
              Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          child: TextFormField(
            controller: _locationController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Address will be filled automatically',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coordinates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _latitudeController.text.isEmpty
                          ? '--'
                          : _latitudeController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Longitude',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _longitudeController.text.isEmpty
                          ? '--'
                          : _longitudeController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        _buildLocationStatus(),
        const SizedBox(height: 20),
        _buildAddressField(),
        const SizedBox(height: 20),
        _buildCoordinates(),

        // Help Text
        Container(
          margin: const EdgeInsets.only(top: 12),
          child: Text(
            'Location helps customers in your area find your services',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
