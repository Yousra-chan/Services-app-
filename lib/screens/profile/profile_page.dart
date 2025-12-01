import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/screens/service/provider_services_screen.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/auth/login/login_screen.dart' hide AuthService;
import 'package:myapp/screens/profile/payment/payment_page.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'package:myapp/screens/profile/settings/settings_page.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/utils/image_utils.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSwitchingRole = false;
  late FirestoreService _firestoreService;
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _firestoreService.getUserStats(widget.user.uid);
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
      // Fallback to user model data
      if (mounted) {
        setState(() {
          _userStats = {
            'address': widget.user.address,
            'totalJobs': widget.user.totalJobs,
            'rating': widget.user.rating,
            'completedJobs': 0,
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        // Use the latest user from AuthViewModel or fallback to initial user
        final UserModel currentUser = authViewModel.currentUser ?? widget.user;
        final bool isProvider = currentUser.isProvider;

        return Scaffold(
          backgroundColor: kLightBackgroundColor,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with gradient
                    _buildProfileHeader(context, currentUser),

                    // Statistics Row
                    _buildStatisticsRow(currentUser),

                    // Role Switch Button
                    _buildRoleSwitchSection(
                        context, currentUser, authViewModel),

                    // My Services Tile (only for providers)
                    if (isProvider) _buildMyServicesTile(context),

                    // Dynamic Info Card
                    _buildRoleOrAddressCard(currentUser, isProvider),

                    const SizedBox(height: 15),

                    // Action/Settings Section
                    _buildActionSection(context, isProvider),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Loading overlay
              if (_isSwitchingRole)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: kPrimaryBlue),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    final double topPadding = MediaQuery.of(context).padding.top;

    // Enhanced debug logging
    print('🖼️ Profile Header Debug:');
    print('📸 User Photo URL: "${user.photoUrl}"');
    print('📏 URL Length: ${user.photoUrl.length}');
    print('🔍 URL Starts with http: ${user.photoUrl.startsWith('http')}');
    print(
        '🔍 URL Starts with data:image: ${user.photoUrl.startsWith('data:image')}');
    print('🔍 Is Base64: ${ImageUtils.isBase64Image(user.photoUrl)}');
    print('🔍 Is Network: ${ImageUtils.isNetworkImage(user.photoUrl)}');
    print('👤 User: ${user.name} (${user.uid})');

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 15, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 12, 94, 153),
            Color(0xFF4A6FDC),
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  CupertinoIcons.back,
                  color: kLightTextColor,
                  size: 28,
                ),
              ),
              const Icon(
                CupertinoIcons.ellipsis_vertical,
                color: kLightTextColor,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Enhanced CircleAvatar with base64 decoding
          _buildEnhancedAvatar(user),

          const SizedBox(height: 15),
          Text(
            user.name,
            style: const TextStyle(
              color: kLightTextColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.role.toUpperCase(),
            style: TextStyle(
              color: kOnlineStatusGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Exo2',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAvatar(UserModel user) {
    final String photoUrl = user.photoUrl;

    // Get the appropriate image provider
    final imageProvider = ImageUtils.getImageProvider(photoUrl);

    if (imageProvider != null) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: kLightBackgroundColor,
        backgroundImage: imageProvider,
        child: _buildImageLoadingFallback(user),
      );
    } else {
      // Fallback when no valid image is available
      return _buildFallbackAvatar(user);
    }
  }

  Widget _buildImageLoadingFallback(UserModel user) {
    return FutureBuilder<bool>(
      future: _checkImageValidity(user.photoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while checking image
          return CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          // Show fallback if image is invalid
          return _buildFallbackAvatar(user);
        }

        // Image is valid, return empty container
        return Container();
      },
    );
  }

  Future<bool> _checkImageValidity(String photoUrl) async {
    try {
      if (ImageUtils.isNetworkImage(photoUrl)) {
        // For network images, check if URL is accessible
        final response = await http.head(Uri.parse(photoUrl));
        return response.statusCode == 200;
      } else if (ImageUtils.isBase64Image(photoUrl)) {
        // For base64 images, check if decoding works
        final bytes = ImageUtils.decodeBase64Image(photoUrl);
        return bytes != null && bytes.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('❌ Image validation error: $e');
      return false;
    }
  }

  Widget _buildFallbackAvatar(UserModel user) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: kLightBackgroundColor,
      child: user.name.isNotEmpty
          ? Text(
              user.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 36,
                color: kPrimaryBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Exo2',
              ),
            )
          : Icon(
              CupertinoIcons.person_fill,
              color: kPrimaryBlue,
              size: 60,
            ),
    );
  }

  // My Services Tile for Providers
  Widget _buildMyServicesTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: kCardBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: kSoftShadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyServicesPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAccentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.wrench_fill,
                      color: kAccentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Services",
                          style: TextStyle(
                            color: kDarkTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Exo2',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Manage your offered services and prices",
                          style: TextStyle(
                            color: kMutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: kMutedTextColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // New section for the role switch button
  Widget _buildRoleSwitchSection(
      BuildContext context, UserModel user, AuthViewModel authViewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: _buildRoleSwitchButton(context, user, authViewModel),
    );
  }

  Widget _buildRoleSwitchButton(
      BuildContext context, UserModel user, AuthViewModel authViewModel) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            kPrimaryBlue.withOpacity(0.9),
            Color(0xFF4A6FDC).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _isSwitchingRole
              ? null
              : () => _showRoleSwitchDialog(context, user, authViewModel),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.isProvider
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.briefcase_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch to ${user.isProvider ? 'Client' : 'Provider'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Exo2',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to change your role',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_isSwitchingRole)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    CupertinoIcons.arrow_right_circle_fill,
                    color: Colors.white.withOpacity(0.9),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleSwitchDialog(
      BuildContext context, UserModel user, AuthViewModel authViewModel) {
    final String newRole = user.isProvider ? 'client' : 'provider';
    final String currentRole = user.role.toUpperCase();
    final String targetRole = newRole.toUpperCase();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: kCardBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.isProvider
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.briefcase_fill,
                    color: kPrimaryBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Switch Role?',
                  style: TextStyle(
                    color: kDarkTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Exo2',
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'You are about to switch from $currentRole to $targetRole mode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMutedTextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Additional info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: kPrimaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.isProvider
                              ? 'As a Client, you can request services from providers.'
                              : 'As a Provider, you can offer services and get hired.',
                          style: TextStyle(
                            color: kDarkTextColor,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kMutedTextColor,
                          side: BorderSide(
                              color: kMutedTextColor.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Switch Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _switchUserRole(
                              context, user, newRole, authViewModel);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Switch',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _switchUserRole(BuildContext context, UserModel user,
      String newRole, AuthViewModel authViewModel) async {
    try {
      setState(() {
        _isSwitchingRole = true;
      });

      print('🔄 Starting role switch from ${user.role} to $newRole');

      // Update role using AuthViewModel
      await authViewModel.updateUserRole(newRole);

      print('✅ Role update completed');

      if (mounted) {
        setState(() {
          _isSwitchingRole = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Role switched to ${newRole.toUpperCase()} successfully!'),
            backgroundColor: kOnlineStatusGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error during role switch: $e');

      if (mounted) {
        setState(() {
          _isSwitchingRole = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch role: $e'),
            backgroundColor: kDangerColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildStatisticsRow(UserModel user) {
    // Use Firebase data if available, otherwise use user data
    final int totalJobs = _userStats?['totalJobs'] ?? user.totalJobs;
    final double rating = _userStats?['rating'] ?? user.rating;
    final int completedJobs = _userStats?['completedJobs'] ?? 0;

    Widget statItem(String label, dynamic value, IconData icon) {
      return Expanded(
        child: Card(
          color: kCardBackgroundColor,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(icon, color: kPrimaryBlue, size: 24),
                const SizedBox(height: 8),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: kDarkTextColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          statItem("Total Jobs", totalJobs, CupertinoIcons.briefcase_fill),
          const SizedBox(width: 10),
          statItem(
              "Rating", rating.toStringAsFixed(1), CupertinoIcons.star_fill),
          const SizedBox(width: 10),
          statItem("Completed", completedJobs,
              CupertinoIcons.checkmark_alt_circle_fill),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    bool isDestructive, {
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading:
              Icon(icon, color: isDestructive ? kDangerColor : kPrimaryBlue),
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive ? kDangerColor : kDarkTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing:
              const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isDestructive) const Divider(height: 1, indent: 20, endIndent: 20),
      ],
    );
  }

  /// Builds the information card based on user address availability or role.
  Widget _buildRoleOrAddressCard(UserModel profile, bool isProvider) {
    String title;
    String content;
    IconData icon;

    // Use Firebase address if available, otherwise use profile address
    final String userAddress = _userStats?['address'] ?? profile.address;

    if (userAddress.isNotEmpty) {
      title = "Address";
      content = userAddress;
      icon = CupertinoIcons.location_solid;
    } else if (isProvider) {
      title = "My Role";
      content = "You are registered as a Service Provider.";
      icon = CupertinoIcons.briefcase_fill;
    } else {
      title = "My Role";
      content = "You are registered as a Client.";
      icon = CupertinoIcons.person_alt_circle_fill;
    }
    return _buildInfoCard(title: title, content: content, icon: icon);
  }

  /// Standardized card container for displaying information.
  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: kSoftShadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kPrimaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Divider(
              color: Color.fromARGB(255, 240, 240, 240),
              height: 20,
            ),
            Text(
              content,
              style: const TextStyle(
                color: kDarkTextColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main list of action tiles (settings, payment, security, logout).
  Widget _buildActionSection(BuildContext context, bool isProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: kSoftShadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            CupertinoIcons.settings,
            "Account Settings",
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          _buildActionTile(
            CupertinoIcons.creditcard,
            "Payment",
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentPage()),
              );
            },
          ),
          _buildActionTile(
            CupertinoIcons.square_arrow_right,
            "Logout",
            true, // Destructive action
            onTap: () async {
              final authService = AuthService();
              await authService.logout();

              if (mounted) {
                // Navigate to Login and clear the stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
