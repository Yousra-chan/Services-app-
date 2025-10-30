import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? photoUrl;
  final GeoPoint? location;
  final String? address;
  final Timestamp? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.location,
    this.address,
    this.createdAt,
  });

  /// Checks if the user's role is 'provider'.
  bool get isProvider => role.toLowerCase() == 'provider';

  /// Checks if the user's role is 'client'.
  bool get isClient => role.toLowerCase() == 'client';

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'client',
      photoUrl: map['photoUrl'],
      location: map['location'] as GeoPoint?,
      address: map['address'],
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'location': location,
      'address': address,
      'createdAt': createdAt,
    };
  }
}
