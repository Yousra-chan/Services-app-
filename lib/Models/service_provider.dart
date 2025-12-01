// models/service_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;
  final String imageUrl;
  final bool isPopular;
  final List<String> searchKeywords;
  final String description;
  final double price;
  final String experience;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    this.imageUrl = '',
    this.isPopular = false,
    this.searchKeywords = const [],
    this.description = '',
    this.price = 0.0,
    this.experience = '',
  });

  factory ServiceProvider.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ServiceProvider(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
      distance: data['distance'] ?? '0 km',
      imageUrl: data['imageUrl'] ?? '',
      isPopular: data['isPopular'] ?? false,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      experience: data['experience'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'rating': rating,
      'reviews': reviews,
      'distance': distance,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'searchKeywords': searchKeywords,
      'description': description,
      'price': price,
      'experience': experience,
    };
  }
}
