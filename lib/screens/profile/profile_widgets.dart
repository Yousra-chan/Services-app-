import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'package:myapp/models/UserModel.dart';

// Profile Header Widget
Widget buildProfileHeader(BuildContext context, UserModel user) {
  final double topPadding = MediaQuery.of(context).padding.top;
  final String userRoleStatus = user.role.toUpperCase();

  return Container(
    padding: EdgeInsets.fromLTRB(20, topPadding + 15, 20, 40),
    decoration: const BoxDecoration(
      color: kPrimaryBlue,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
      ],
    ),
    child: Column(
      children: [
        // Top Row: Back Button and Options
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

        // Profile Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: kLightBackgroundColor,
              backgroundImage:
                  user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child:
                  user.photoUrl.isEmpty
                      ? Icon(
                        CupertinoIcons.person_fill,
                        color: kPrimaryBlue,
                        size: 60,
                      )
                      : null,
            ),
          ],
        ),
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
          userRoleStatus,
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

// Statistics Item Widget
Widget _buildStatItem(String label, int value, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: kPrimaryBlue, size: 30),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              color: kPrimaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: kMutedTextColor,
              fontSize: 12,
              fontFamily: 'Exo2',
            ),
          ),
        ],
      ),
    ),
  );
}

// Statistics Row Widget
Widget buildStatisticsRow(UserModel user) {
  // Use actual user data or placeholders
  final int servicesCount = user.totalJobs;
  final int ratingValue = user.rating.round();
  final int postsCount = 87; // Placeholder or add to UserModel

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Row(
      children: [
        _buildStatItem(
          "Services",
          servicesCount,
          CupertinoIcons.briefcase_fill,
        ),
        const SizedBox(width: 15),
        _buildStatItem("Rating", ratingValue, CupertinoIcons.star_fill),
        const SizedBox(width: 15),
        _buildStatItem("Posts", postsCount, CupertinoIcons.doc_text),
      ],
    ),
  );
}

// Action Tile Widget
Widget buildActionTile(
  IconData icon,
  String title,
  bool isLast, {
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, top: 2),
    child: Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryBlue, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Exo2',
            ),
          ),
          trailing: const Icon(CupertinoIcons.forward, color: kMutedTextColor),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 75,
            color: Color.fromARGB(255, 230, 230, 230),
          ),
      ],
    ),
  );
}

// Info Card Widget (for address/role display)
Widget buildInfoCard({
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
          const Divider(color: Color.fromARGB(255, 240, 240, 240), height: 20),
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

// Role or Address Card Builder
Widget buildRoleOrAddressCard(UserModel profile) {
  final bool isProvider = profile.isProvider;
  String title;
  String content;
  IconData icon;

  if (profile.address.isNotEmpty) {
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

  return buildInfoCard(title: title, content: content, icon: icon);
}

// Section Header Widget
Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: kDarkTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Exo2',
      ),
    ),
  );
}

// Loading State Widget
Widget buildProfileLoadingState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: kPrimaryBlue),
        const SizedBox(height: 20),
        Text(
          "Loading Profile...",
          style: TextStyle(color: kMutedTextColor, fontSize: 16),
        ),
      ],
    ),
  );
}

// Error State Widget
Widget buildProfileErrorState(String errorMessage) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: kDangerColor,
          size: 50,
        ),
        const SizedBox(height: 20),
        Text(
          "Error Loading Profile",
          style: TextStyle(
            color: kDangerColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: kMutedTextColor, fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Add retry logic here
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Try Again"),
        ),
      ],
    ),
  );
}
