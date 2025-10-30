import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// --- Global Constants (Consistent with previous screens) ---
// Primary Blue (Vibrant)
const Color kPrimaryBlue = Color.fromARGB(255, 12, 94, 153);
// Light Background Color (for the Scaffold)
const Color kLightBackgroundColor = Color.fromARGB(255, 248, 249, 255);
// Card/Tile Background: Pure white
const Color kCardBackgroundColor = Colors.white;
// Text Colors
const Color kDarkTextColor = Color.fromARGB(255, 50, 50, 50);
const Color kMutedTextColor = Color.fromARGB(255, 150, 150, 150);
const Color kSoftShadowColor = Color.fromARGB(50, 87, 101, 240);
const Color kRatingYellow = Color.fromARGB(
  255,
  255,
  193,
  7,
); // Standard yellow for ratings

// --- Data Models ---
class ServiceCategory {
  final String name;
  final IconData icon;

  ServiceCategory({required this.name, required this.icon});
}

class ServiceProvider {
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;

  ServiceProvider({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
  });
}


final List<ServiceCategory> categories = [

  ServiceCategory(name: "Teaching", icon: CupertinoIcons.pencil),
  ServiceCategory(name: "Health", icon: CupertinoIcons.heart_fill),

  ServiceCategory(name: "Mechanic", icon: CupertinoIcons.car_fill),
  ServiceCategory(name: "Clean", icon: CupertinoIcons.sparkles),
];

final List<ServiceProvider> popularProviders = [
  ServiceProvider(
    name: "Dr. Ahmed Hassan",
    category: "Pediatrician",
    rating: 4.9,
    reviews: 540,
    distance: "1.2 km",
  ),
  ServiceProvider(
    name: "Khaled Electrics",
    category: "Electrician",
    rating: 4.7,
    reviews: 210,
    distance: "3.5 km",
  ),
  ServiceProvider(
    name: "Sara Plumbing",
    category: "Plumber",
    rating: 4.5,
    reviews: 155,
    distance: "0.8 km",
  ),
  ServiceProvider(
    name: "Tutor Omar",
    category: "Math Tutor",
    rating: 5.0,
    reviews: 98,
    distance: "5.1 km",
  ),
];
