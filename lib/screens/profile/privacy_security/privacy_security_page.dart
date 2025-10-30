import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'privacy_security_widgets.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  // Local state for security toggles
  bool _twoFactorEnabled = true;
  bool _locationSharing = false;
  bool _activityStatusHidden = false;
  bool _biometricLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        // Custom App Bar style
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: kLightTextColor,
            size: 28,
          ),
        ),
        title: const Text(
          "Privacy & Security",
          style: TextStyle(
            color: kLightTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),

            // --- 1. Security Section ---
            buildSettingsSectionTitle("SECURITY"),
            buildActionCard(
              children: [
                buildSwitchTile(
                  CupertinoIcons.lock_shield_fill,
                  "2-Factor Authentication",
                  _twoFactorEnabled,
                  (bool newValue) {
                    setState(() {
                      _twoFactorEnabled = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.person_alt_circle_fill,
                  "Biometric Login",
                  _biometricLogin,
                  (bool newValue) {
                    setState(() {
                      _biometricLogin = newValue;
                    });
                  },
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.person_2_fill,
                  "Manage Blocked Users",
                  true,
                ),
              ],
            ),

            // --- 2. Privacy Controls Section ---
            buildSettingsSectionTitle("PRIVACY CONTROLS"),
            buildActionCard(
              children: [
                buildSwitchTile(
                  CupertinoIcons.location_fill,
                  "Location Sharing",
                  _locationSharing,
                  (bool newValue) {
                    setState(() {
                      _locationSharing = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.eye_slash_fill,
                  "Hide Activity Status",
                  _activityStatusHidden,
                  (bool newValue) {
                    setState(() {
                      _activityStatusHidden = newValue;
                    });
                  },
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.person_crop_circle_fill_badge_xmark,
                  "Who Can View My Profile",
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.hand_raised_fill,
                  "Data Permissions",
                  true,
                ),
              ],
            ),

            // --- 3. Data & Backup Section ---
            buildSettingsSectionTitle("DATA & BACKUP"),
            buildActionCard(
              children: [
                buildActionTile(
                  CupertinoIcons.cloud_upload_fill,
                  "Export My Data",
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.arrow_counterclockwise_circle_fill,
                  "Data Retention Policy",
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.bin_xmark_fill,
                  "Permanently Delete Data",
                  true,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
