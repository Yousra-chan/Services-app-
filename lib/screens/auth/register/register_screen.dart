import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/auth/login/login_screen.dart';
import 'package:myapp/screens/navigator_bottom.dart';
import 'registration_widget.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  // Form fields state
  String _name = '';
  String _email = '';
  String _password = '';
  String _role = 'client';
  String _phone = '';
  String _address = '';

  // Geolocation state variables
  Position? _currentPosition;
  String _locationMessage = 'Tap the button to set your precise GPS location.';
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Determine the current position of the device.
  Future<void> _determinePosition() async {
    setState(() {
      _locationMessage = 'Requesting location and checking permissions...';
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _currentPosition = null;
      _locationMessage = 'Location services are disabled. Please enable them.';
      setState(() {});
      return;
    }

    // Check current permission status.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if denied once.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _currentPosition = null;
        _locationMessage = 'Location permissions are denied.';
        setState(() {});
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _currentPosition = null;
      _locationMessage = 'Permissions permanently denied. Enable in settings.';
      setState(() {});
      return;
    }

    // Permissions are granted, now fetch the position.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Update state upon success
      setState(() {
        _currentPosition = position;
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = 'Location fetched successfully!';
      });
    } catch (e) {
      // Update state upon error
      setState(() {
        _currentPosition = null;
        _latitude = null;
        _longitude = null;
        _locationMessage = 'Error fetching position: ${e.toString()}';
      });
    }
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    // Get the real AuthViewModel from Provider
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    try {
      print('📱 Starting registration process...');
      print('   Name: $_name');
      print('   Email: $_email');
      print('   Role: $_role');
      print('   Phone: $_phone');
      print('   Address: $_address');
      print('   Location: $_latitude, $_longitude');

      // Use the real AuthViewModel signup method
      await authViewModel.signup(
        name: _name,
        email: _email,
        password: _password,
        role: _role,
        phone: _phone,
        address: _address,
        lat: _latitude,
        lon: _longitude,
      );

      if (!mounted) return;

      print('📱 Registration completed in UI');

      // Check if registration was successful
      if (authViewModel.currentUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account Created for: ${authViewModel.currentUser!.name}!',
            ),
            backgroundColor: kPrimaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate to home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NavigatorBottom()),
          (route) => false,
        );
      } else {
        throw Exception('Registration failed - no user data');
      }
    } catch (e) {
      if (!mounted) return;

      String messageToDisplay;
      if (e is Exception) {
        messageToDisplay = e.toString().replaceFirst('Exception: ', '');
      } else {
        messageToDisplay = 'An unexpected error occurred.';
      }

      print('❌ Registration error: $messageToDisplay');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: $messageToDisplay'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(
          CupertinoIcons.arrow_left,
          color: kMutedTextColor,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 120, height: 120),
          const SizedBox(height: 16),
          const Text(
            'Akhdem Li',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: kAppFont,
              color: kDarkTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeolocationSection() {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.location_off;

    if (_currentPosition != null) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (_locationMessage.contains('Error') ||
        _locationMessage.contains('denied')) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    } else if (_locationMessage.contains('Requesting')) {
      statusColor = kPrimaryBlue;
      statusIcon = Icons.info_outline;
    }

    String displayCoordinates =
        _currentPosition != null
            ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}'
            : _locationMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _determinePosition,
            icon: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
            label: const Text(
              'Get My Current GPS Location',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayCoordinates,
                style: TextStyle(
                  fontFamily: kAppFont,
                  fontSize: 14,
                  color: statusColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I want to:',
          style: TextStyle(
            fontFamily: kAppFont,
            color: kDarkTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RoleOption(
                title: 'Find Services',
                subtitle: 'I need help with tasks',
                icon: Icons.person_outline,
                isSelected: _role == 'client',
                onTap: () {
                  setState(() {
                    _role = 'client';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RoleOption(
                title: 'Offer Services',
                subtitle: 'I provide services',
                icon: Icons.business_center_outlined,
                isSelected: _role == 'provider',
                onTap: () {
                  setState(() {
                    _role = 'provider';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the real AuthViewModel to access isLoading state
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kHorizontalPadding,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Bar (Back Button)
                _buildTopBar(context),

                // 2. Logo Placement (Centered and separate)
                const SizedBox(height: 100),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 30),

                // 3. Main Content Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: kDarkTextColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: kAppFont,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start your journey with us!',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: kMutedTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: kAppFont,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Registration Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name Field
                            TextFormField(
                              decoration: buildAestheticInputDecoration(
                                'Full Name',
                              ),
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Please enter your name'
                                          : null,
                              onSaved: (value) => _name = value!,
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              decoration: buildAestheticInputDecoration(
                                'Email Address',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty || !value.contains('@')
                                          ? 'Please enter a valid email address'
                                          : null,
                              onSaved: (value) => _email = value!,
                            ),
                            const SizedBox(height: 16),

                            // Phone Field
                            TextFormField(
                              decoration: buildAestheticInputDecoration(
                                'Phone Number',
                              ),
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Please enter your phone number'
                                          : null,
                              onSaved: (value) => _phone = value!,
                            ),
                            const SizedBox(height: 16),

                            // Address Field
                            TextFormField(
                              decoration: buildAestheticInputDecoration(
                                'Full Address (Street, City, Postal Code)',
                              ),
                              keyboardType: TextInputType.streetAddress,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty && _latitude == null
                                          ? 'Please enter your address or get your GPS location'
                                          : null,
                              onSaved: (value) => _address = value!,
                            ),
                            const SizedBox(height: 16),

                            // GPS Location Section
                            _buildGeolocationSection(),
                            const SizedBox(height: 16),

                            // Role Selection
                            _buildRoleSelection(),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              decoration: buildAestheticInputDecoration(
                                'Password',
                              ),
                              obscureText: true,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.length < 6
                                          ? 'Password must be at least 6 characters'
                                          : null,
                              onSaved: (value) => _password = value!,
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            TextFormField(
                              decoration: buildAestheticInputDecoration(
                                'Confirm Password',
                              ),
                              obscureText: true,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Register Button - Use real loading state from AuthViewModel
                            RegisterButton(
                              isLoading: authViewModel.isLoading,
                              onPressed: _submitRegistration,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      const OrDivider(),

                      const SizedBox(height: 20),
                      const SocialSignInRow(),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Sign In Link
                SignInLink(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
