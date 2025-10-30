import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'profile_constants.dart';
import 'profile_widgets.dart';
import 'package:myapp/screens/profile/notifications/notification_page.dart';
import 'package:myapp/screens/profile/payment/payment_page.dart';
import 'package:myapp/screens/profile/privacy_security/privacy_security_page.dart';
import 'package:myapp/screens/profile/settings/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the dummy data defined in constants
    final UserProfile profile = dummyProfile;

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header (Curved blue section with Avatar and Name)
            buildProfileHeader(context, profile),

            // 2. Statistics Row (Three Card-based stat items)
            buildStatisticsRow(profile),

            // 3. Bio and Location Card
            _buildInfoCard(
              title: "My Services",
              content: profile.bio,
              icon: CupertinoIcons.info_circle_fill,
            ),

            const SizedBox(height: 15),

            // 4. Action/Settings Section
            _buildActionSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Standardized card container for info like Bio/Location
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
                    fontFamily: 'Exo2',
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
                fontFamily: 'Exo2',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    return Builder(
      builder: (context) {
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
                  // Navigation to SettingsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
              buildActionTile(
                CupertinoIcons.creditcard,
                "Payement",
                false,
                onTap: () {
                  // Navigation to PaymentPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentPage(),
                    ),
                  );
                },
              ),
              buildActionTile(
                CupertinoIcons.lock_fill,
                "Privacy & Security",
                false,
                onTap: () {
                  // Navigation to PrivacySecurityPage
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
                  // Navigation to NotificationsPage
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
                true,
                onTap: () {
                  //logout logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logging out...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
