import 'package:flutter/material.dart';

// --- Global Constants (Consistent with previous screens) ---
// Primary Blue (Vibrant from the image)
const Color kPrimaryBlue = Color.fromARGB(255, 12, 94, 153);
// Light Background Color (for the Scaffold)
const Color kLightBackgroundColor = Color.fromARGB(255, 248, 249, 255);
// Card/Tile Background: Pure white
const Color kCardBackgroundColor = Colors.white;
// Text Colors
const Color kDarkTextColor = Color.fromARGB(255, 50, 50, 50);
const Color kMutedTextColor = Color.fromARGB(255, 150, 150, 150);
const Color kOnlineStatusGreen = Color.fromARGB(255, 76, 175, 80);
const Color kSoftShadowColor = Color.fromARGB(50, 87, 101, 240);
const Color kLightTextColor = Color.fromARGB(255, 248, 249, 255);
const Color kDangerColor = Color.fromARGB(255, 239, 83, 80);

class UserProfile {
  final String name;
  final String status;
  final String bio;
  final String location;
  final int friends;
  final int chats;
  final int mediaCount;

  UserProfile({
    required this.name,
    required this.status,
    required this.bio,
    required this.location,
    required this.friends,
    required this.chats,
    required this.mediaCount,
  });
}

final UserProfile dummyProfile = UserProfile(
  name: "Julian Dasilva",
  status: "Online",
  bio: "",
  location: "Cairo, Egypt",
  friends: 1240,
  chats: 87,
  mediaCount: 350,
);
