import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'settings_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Local state for switch tiles
  bool _darkModeEnabled = false;
  bool _sendReadReceipts = true;
  bool _offlineMode = false;

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
          "Account Settings",
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

            // --- 1. Account Settings Section ---
            buildSettingsSectionTitle("ACCOUNT"),
            buildActionCard(
              children: [
                buildActionTile(
                  CupertinoIcons.person_alt_circle_fill,
                  "Edit Profile",
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.lock_shield_fill,
                  "Change Password",
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.mail_solid,
                  "Update Email",
                  true,
                ),
              ],
            ),

            // --- 2. General Settings Section ---
            buildSettingsSectionTitle("GENERAL"),
            buildActionCard(
              children: [
                buildSwitchTile(
                  CupertinoIcons.moon_fill,
                  "Dark Mode",
                  _darkModeEnabled,
                  (bool newValue) {
                    setState(() {
                      _darkModeEnabled = newValue;
                    });
                  },
                  false,
                ),
                buildActionTile(CupertinoIcons.globe, "Language", false),
                buildActionTile(
                  CupertinoIcons.gear_alt_fill,
                  "Advanced Settings",
                  true,
                ),
              ],
            ),

            // --- 3. Privacy Settings Section ---
            buildSettingsSectionTitle("PRIVACY & DATA"),
            buildActionCard(
              children: [
                buildSwitchTile(
                  CupertinoIcons.eye_slash_fill,
                  "Send Read Receipts",
                  _sendReadReceipts,
                  (bool newValue) {
                    setState(() {
                      _sendReadReceipts = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.power,
                  "Offline Mode",
                  _offlineMode,
                  (bool newValue) {
                    setState(() {
                      _offlineMode = newValue;
                    });
                  },
                  false,
                ),
                buildActionTile(
                  CupertinoIcons.delete_solid,
                  "Clear Cache",
                  true,
                ),
              ],
            ),

            // --- 4. Danger Zone ---
            buildSettingsSectionTitle("DANGER ZONE"),
            buildActionCard(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 5,
                  ),
                  title: const Text(
                    "Delete Account",
                    style: TextStyle(
                      color: kDangerColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.trash_fill,
                    color: kDangerColor,
                  ),
                  onTap: () {
                    // Show confirmation dialog for account deletion
                  },
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
