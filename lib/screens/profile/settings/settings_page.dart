import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'package:myapp/screens/profile/settings/change_password_page.dart';
import 'package:myapp/screens/profile/settings/update_email_page.dart';
import 'settings_widgets.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Local state for switch tiles
  final bool _darkModeEnabled = false;
  final bool _sendReadReceipts = true;
  final bool _offlineMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
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
                  onTap: () => _navigateToEditProfile(context),
                ),
                buildActionTile(
                  CupertinoIcons.lock_shield_fill,
                  "Change Password",
                  false,
                  onTap: () => _navigateToChangePassword(context),
                ),
                buildActionTile(
                  CupertinoIcons.mail_solid,
                  "Update Email",
                  false,
                  onTap: () => _navigateToUpdateEmail(context),
                ),
              ],
            ),

            // --- 2. General Settings Section ---
            buildSettingsSectionTitle("GENERAL"),
            buildActionCard(
              children: [
                buildActionTile(
                  CupertinoIcons.globe,
                  "Language",
                  false,
                  onTap: () => _showLanguageDialog(context),
                ),
              ],
            ),

            // --- 3. Danger Zone ---
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
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
    );
  }

  void _navigateToUpdateEmail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpdateEmailPage()),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Select Language"),
        content: const Text("Language selection will be implemented here."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "This action cannot be undone. All your data will be permanently deleted."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion logic
            },
          ),
        ],
      ),
    );
  }
}
