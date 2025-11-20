class Service {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final String category;
  final double price;
  final String priceUnit;
  final List<String> images;
  final String location;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating;
  final int totalReviews;
  final List<String> tags;

  Service({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.priceUnit,
    this.images = const [],
    required this.location,
    this.latitude,
    this.longitude,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.tags = const [],
  });

  // Add these methods if missing
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'priceUnit': priceUnit,
      'images': images,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'rating': rating,
      'totalReviews': totalReviews,
      'tags': tags,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      priceUnit: map['priceUnit'] ?? 'per service',
      images: List<String>.from(map['images'] ?? []),
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Helper methods
  String get displayPrice {
    return '\$$price $priceUnit';
  }

  String get shortDescription {
    if (description.length <= 100) return description;
    return '${description.substring(0, 100)}...';
  }

  bool get hasLocation => latitude != null && longitude != null;
}
