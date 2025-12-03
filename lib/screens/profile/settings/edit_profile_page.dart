import 'package:flutter/material.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'dart:convert';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _currentUser = authViewModel.currentUser!; // Initialize _currentUser

    _nameController = TextEditingController(text: _currentUser.name);
    _phoneController = TextEditingController(text: _currentUser.phone);
    _addressController = TextEditingController(text: _currentUser.address);

    authViewModel.addListener(_updateCurrentUser);
  }

  void _updateCurrentUser() {
    // Check if the widget is still in the tree before using context
    if (mounted) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      setState(() {
        _currentUser = authViewModel.currentUser!;
      });
    }
  }

  @override
  void dispose() {
    // Only dispose if the context is still available
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.removeListener(_updateCurrentUser); // Remove listener
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- Updated Function: Handling Photo Upload ---
  Future<void> _handlePhotoChange() async {
    // 1. Set loading state
    setState(() => _isLoading = true);

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // 2. 🎯 Use the new pickImageAndEncode method (no userId needed)
      final String? newPhotoUrl = await authViewModel.pickImageAndEncode();

      // 3. If a new URL/Base64 string is returned, update the user profile.
      if (newPhotoUrl != null) {
        // 4. Use copyWith for clean update
        final updatedUser = _currentUser.copyWith(photoUrl: newPhotoUrl);
        await authViewModel.updateUserProfile(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: kSuccessColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Updated Function: Handling Profile Update ---
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // 🎯 Use copyWith to update only the fields that have changed (name, phone, address)
      final updatedUser = _currentUser.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        // All other fields (uid, email, photoUrl, etc.) remain as they were in _currentUser
      );

      await authViewModel.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: kSuccessColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the AuthViewModel to get the latest user data for the build
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser!;

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kLightTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: kLightTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              _buildProfilePicture(user, _handlePhotoChange, _isLoading),
              const SizedBox(height: 30),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 8) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Update Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 UPDATED: Logic to handle Base64 string for display
  Widget _buildProfilePicture(
      UserModel user, VoidCallback onCameraTap, bool isLoading) {
    // 1. Check if the photoUrl field contains a Base64 string
    final isBase64 = user.photoUrl.startsWith('data:');

    // 2. Determine the image widget based on content type
    Widget imageWidget;

    if (user.photoUrl.isNotEmpty) {
      if (isBase64) {
        // Extract the Base64 data part (after 'data:image/jpeg;base64,')
        final base64String = user.photoUrl.split(',').last;
        try {
          // Use Image.memory to display raw bytes from the Base64 string
          imageWidget = ClipOval(
            child: Image.memory(
              base64Decode(base64String),
              fit: BoxFit.cover,
              width: 100, // Matches CircleAvatar radius * 2
              height: 100,
              // Fallback for corrupt data
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
          );
        } catch (e) {
          // Decoding failed (corrupt data)
          imageWidget = const Icon(Icons.error, size: 50, color: kDangerColor);
        }
      } else {
        // Fallback for external network URLs (if you still have any)
        imageWidget = ClipOval(
          child: Image.network(
            user.photoUrl,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            // Fallback for failed network load
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
        );
      }
    } else {
      // Default placeholder icon
      imageWidget = const Icon(
        Icons.person,
        size: 50,
        color: Colors.grey,
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: kPrimaryBlue.withOpacity(0.1),
              child: imageWidget, // Display the calculated widget
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: isLoading ? null : onCameraTap, // Handle tap
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: isLoading ? null : onCameraTap,
          child: Text(
            isLoading ? 'Uploading...' : 'Change Photo',
            style: TextStyle(
              color: kPrimaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kMutedTextColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kMutedTextColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryBlue),
        ),
      ),
      validator: validator,
    );
  }
}
