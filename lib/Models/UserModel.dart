import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String photoUrl;
  final Timestamp createdAt;
  final GeoPoint? location;
  final String address;
  final int totalJobs;
  final double rating;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.photoUrl,
    required this.createdAt,
    this.location,
    required this.address,
    this.totalJobs = 0,
    this.rating = 0.0,
    this.fcmToken,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'location': location,
      'address': address,
      'totalJobs': totalJobs,
      'rating': rating,
      'fcmToken': fcmToken,
    };
  }

  // Create UserModel from Firestore data
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'client',
      photoUrl: data['photoUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      location: data['location'],
      address: data['address'] ?? '',
      totalJobs: data['totalJobs'] ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      fcmToken: data['fcmToken'],
    );
  }

  // Helper getters to check user roles
  bool get isProvider => role == 'provider';
  bool get isClient => role == 'client';
}
