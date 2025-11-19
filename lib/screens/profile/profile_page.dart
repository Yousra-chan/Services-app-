import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/screens/auth/login/login_screen.dart' hide AuthService;
import 'package:myapp/screens/profile/notifications/notification_page.dart';
import 'package:myapp/screens/profile/payment/payment_page.dart';
import 'package:myapp/screens/profile/privacy_security/privacy_security_page.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'package:myapp/screens/profile/settings/settings_page.dart';

Widget buildProfileHeader(BuildContext context, UserModel user) {
  return Container(
    width: double.infinity,
    height: 250,
    decoration: BoxDecoration(
      color: kPrimaryBlue,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user.role,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildStatisticsRow(UserModel user) {
  Widget statItem(String label, String value) {
    return Expanded(
      child: Card(
        color: kCardBackgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                value,
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
        statItem("Total Jobs", user.totalJobs.toString()),
        statItem("Rating", user.rating.toStringAsFixed(1)),
      ],
    ),
  );
}

Widget buildActionTile(
  IconData icon,
  String title,
  bool isDestructive, {
  required VoidCallback onTap,
}) {
  return Column(
    children: [
      ListTile(
        leading: Icon(icon, color: isDestructive ? kDangerColor : kPrimaryBlue),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? kDangerColor : kDarkTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
      if (!isDestructive) const Divider(height: 1, indent: 20, endIndent: 20),
    ],
  );
}

class ProfilePage extends StatelessWidget {
  final UserModel user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final UserModel profile = user;
    final bool isProvider = profile.isProvider;

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            buildProfileHeader(context, profile),

            // Statistics Row
            buildStatisticsRow(profile),

            // Dynamic Info Card: Shows Address if available, otherwise Role
            _buildRoleOrAddressCard(profile, isProvider),

            const SizedBox(height: 15),

            // Action/Settings Section
            _buildActionSection(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Builds the information card based on user address availability or role.
  Widget _buildRoleOrAddressCard(UserModel profile, bool isProvider) {
    String title;
    String content;
    IconData icon;

    if (profile.address.isNotEmpty) {
      // Fixed: address is not nullable in your UserModel
      title = "Address";
      content = profile.address;
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
  Widget _buildActionSection(BuildContext context) {
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
          buildActionTile(
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
          buildActionTile(
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
          buildActionTile(
            CupertinoIcons.lock_fill,
            "Privacy & Security",
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySecurityPage(),
                ),
              );
            },
          ),
          buildActionTile(
            CupertinoIcons.bell_fill,
            "Notifications",
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
          buildActionTile(
            CupertinoIcons.square_arrow_right,
            "Logout",
            true, // Destructive action
            onTap: () async {
              final authService = AuthService();
              await authService.logout();

              if (context.mounted) {
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
