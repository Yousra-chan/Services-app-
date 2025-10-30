import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';

Widget buildProfileHeader(BuildContext context, UserProfile profile) {
  final double topPadding = MediaQuery.of(context).padding.top;

  return Container(
    padding: EdgeInsets.fromLTRB(
      20,
      topPadding + 15,
      20,
      40,
    ), // Increased bottom padding
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
              child: Icon(
                CupertinoIcons.person_fill,
                color: kPrimaryBlue,
                size: 60,
              ),
            ),
            // Online Status Dot
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: kOnlineStatusGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        Text(
          profile.name,
          style: const TextStyle(
            color: kLightTextColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.status,
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

Widget buildStatisticsRow(UserProfile profile) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Row(
      children: [
        _buildStatItem(
          "Services",
          profile.friends,
          CupertinoIcons.briefcase_fill,
        ),
        const SizedBox(width: 15),
        _buildStatItem("Psts", profile.chats, CupertinoIcons.doc_text),
        const SizedBox(width: 15),
      ],
    ),
  );
}

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
            indent: 75, // Aligns with the title text
            color: Color.fromARGB(255, 230, 230, 230),
          ),
      ],
    ),
  );
}
