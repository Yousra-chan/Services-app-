import 'package:flutter/material.dart';

// --- Colors (Consistent with previous screens) ---
const Color kPrimaryBlue = Color.fromARGB(255, 12, 94, 153);
const Color kLightBackgroundColor = Color.fromARGB(255, 248, 249, 255);
const Color kCardBackgroundColor = Colors.white;
const Color kDarkTextColor = Color.fromARGB(255, 50, 50, 50);
const Color kMutedTextColor = Color.fromARGB(255, 150, 150, 150);
const Color kSoftShadowColor = Color.fromARGB(50, 87, 101, 240);

// --- Post Type Colors ---
// Reddish for "I need service" (Seeking help)
const Color kSeekingColor = Color.fromARGB(255, 255, 100, 100);
// Greenish for "I offer service" (Giving help)
const Color kOfferingColor = Color.fromARGB(255, 100, 200, 100);
const Color kAccentColor = Color(0xFFFFB300);

const double kDummyPriceEstimate = 5000.00;
const List<String> kDummyWorkImages = [
  'https://picsum.photos/id/400/400/300',
  'https://picsum.photos/id/401/400/300',
  'https://picsum.photos/id/402/400/300',
  'https://picsum.photos/id/403/400/300',
];

// --- Data Model ---
enum PostType { seeking, offering }

class Post {
  final String title;
  final String body;
  final String user;
  final PostType type; // Seeking or Offering
  final String serviceCategory;
  final DateTime timestamp;

  Post({
    required this.title,
    required this.body,
    required this.user,
    required this.type,
    required this.serviceCategory,
    required this.timestamp,
  });
}

final List<Post> dummyPosts = [
  Post(
    title: "Looking for Plumber ASAP!",
    body:
        "Leak in the bathroom, need someone reliable and fast. Located in the City Center. Available to meet this evening.",
    user: "Ahmed M.",
    type: PostType.seeking,
    serviceCategory: "Plumbing",
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  Post(
    title: "Offering Electrical Repair Services",
    body:
        "Certified electrician with 10 years experience. Available for wiring, fixture installation, and emergency troubleshooting. Contact me for a quote!",
    user: "Khaled E.",
    type: PostType.offering,
    serviceCategory: "Electrician",
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  Post(
    title: "Need Math Tutor for High School",
    body:
        "My son needs help with Calculus. Looking for a patient and experienced tutor, preferably near the North District.",
    user: "Sara H.",
    type: PostType.seeking,
    serviceCategory: "Tutoring",
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Post(
    title: "Handyman services available this weekend",
    body:
        "General repairs, furniture assembly, painting, and minor construction tasks. Affordable rates and prompt service.",
    user: "Omar G.",
    type: PostType.offering,
    serviceCategory: "Handyman",
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
  ),
];
