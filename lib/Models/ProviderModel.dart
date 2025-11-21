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

  factory ProviderModel.fromMap(Map<String, dynamic> map, String docId) {
    // Safely parse GeoPoint
    GeoPoint? geoPoint;
    if (map['location'] is GeoPoint) {
      geoPoint = map['location'] as GeoPoint;
    }

    // Safely parse services list
    final servicesList = map['services'];
    List<String> services = (servicesList is List)
        ? List<String>.from(servicesList.map((x) => x.toString()))
        : [];

    // Safely parse userRef - handle cases where it might not exist
    DocumentReference userRef;
    try {
      userRef = map['userRef'] as DocumentReference;
    } catch (e) {
      // Create a dummy reference or handle appropriately
      userRef = FirebaseFirestore.instance.collection('users').doc(docId);
    }

    // Safely parse subscriptionActive
    bool subscriptionActive = false;
    if (map['subscriptionActive'] != null) {
      subscriptionActive = map['subscriptionActive'] == true;
    }

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
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      subscriptionActive: subscriptionActive,
      subscriptionExpires: map['subscriptionExpires'] as Timestamp?,
      userRef: userRef,
      services: services,
    );
  }
}
