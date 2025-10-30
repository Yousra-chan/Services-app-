import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'package:myapp/screens/profile/notifications/notification_widget.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Local state for notification toggles
  bool _pushNotificationsEnabled = true;
  bool _emailAlertsEnabled = false;

  // Specific alert categories
  bool _newFriendRequests = true;
  bool _messageAlerts = true;
  bool _promotionalOffers = false;
  bool _securityAlerts = true;
  bool _soundAndVibration = true;

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
          "Notifications",
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

            // --- 1. Global Settings Section ---
            buildSettingsSectionTitle("GENERAL SETTINGS"),
            buildActionCard(
              children: [
                buildSwitchTile(
                  CupertinoIcons.bell_fill,
                  "Push Notifications",
                  _pushNotificationsEnabled,
                  (bool newValue) {
                    setState(() {
                      _pushNotificationsEnabled = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.mail_solid,
                  "Email Alerts",
                  _emailAlertsEnabled,
                  (bool newValue) {
                    setState(() {
                      _emailAlertsEnabled = newValue;
                    });
                  },
                  true,
                ),
              ],
            ),

            // --- 2. Activity Alerts Section ---
            buildSettingsSectionTitle("ACTIVITY ALERTS"),
            buildActionCard(
              children: [
                buildSwitchTile(
                  CupertinoIcons.person_add_solid,
                  "New Friend Requests",
                  _newFriendRequests,
                  (bool newValue) {
                    setState(() {
                      _newFriendRequests = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.chat_bubble_2_fill,
                  "Direct Messages",
                  _messageAlerts,
                  (bool newValue) {
                    setState(() {
                      _messageAlerts = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.lightbulb_fill,
                  "App Updates & Features",
                  true, // Always on (example)
                  (bool newValue) {
                    // Do nothing or show a message if this is required
                  },
                  true,
                ),
              ],
            ),

            // --- 3. Additional Settings Section ---
            buildSettingsSectionTitle("PREFERENCES"),
            buildActionCard(
              children: [
                buildSwitchTile(
                  CupertinoIcons.volume_up,
                  "Sound & Vibration",
                  _soundAndVibration,
                  (bool newValue) {
                    setState(() {
                      _soundAndVibration = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.lock_fill,
                  "Critical Security Alerts",
                  _securityAlerts,
                  (bool newValue) {
                    setState(() {
                      _securityAlerts = newValue;
                    });
                  },
                  false,
                ),
                buildSwitchTile(
                  CupertinoIcons.tag_fill,
                  "Promotional Offers",
                  _promotionalOffers,
                  (bool newValue) {
                    setState(() {
                      _promotionalOffers = newValue;
                    });
                  },
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
