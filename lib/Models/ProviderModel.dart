import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderModel {
  String? uid;
  final String name;
  final String profession;
  final String description;
  final String phone;
  final String whatsapp;
  final String? photoUrl;
  final GeoPoint? location;
  final String address;
  final double rating;
  final bool subscriptionActive;
  final Timestamp? subscriptionExpires;
  final DocumentReference userRef;
  final List<String> services;

  ProviderModel({
    this.uid,
    required this.name,
    required this.profession,
    required this.description,
    required this.phone,
    required this.whatsapp,
    this.photoUrl,
    this.location,
    required this.address,
    required this.rating,
    required this.subscriptionActive,
    this.subscriptionExpires,
    required this.userRef,
    required this.services,
  });

  // Factory method to create a model from Firestore data
  factory ProviderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    // Safely parse GeoPoint
    GeoPoint? geoPoint;
    if (map['location'] is GeoPoint) {
      geoPoint = map['location'] as GeoPoint;
    }

    // Safely parse services list
    final servicesList = map['services'];
    List<String> services =
        (servicesList is List)
            ? List<String>.from(servicesList.map((x) => x.toString()))
            : [];

    return ProviderModel(
      uid: docId,
      name: map['name'] ?? '',
      profession: map['profession'] ?? '',
      description: map['description'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      photoUrl: map['photoUrl'],
      location: geoPoint,
      address: map['address'] ?? '',
      rating: (map['rating'] is num) ? map['rating'].toDouble() : 0.0,
      subscriptionActive: map['subscriptionActive'] ?? false,
      subscriptionExpires: map['subscriptionExpires'] as Timestamp?,
      userRef: map['userRef'] as DocumentReference,
      services: services,
    );
  }

  //convert the model to a Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profession': profession,
      'description': description,
      'phone': phone,
      'whatsapp': whatsapp,
      'photoUrl': photoUrl,
      'location': location,
      'address': address,
      'rating': rating,
      'subscriptionActive': subscriptionActive,
      'subscriptionExpires': subscriptionExpires,
      'userRef': userRef,
      'services': services,
    };
  }
}
