import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  String? id;
  final String name;
  final String description;
  final String? iconUrl;
  final String category;
  final String providerId;

  final DocumentReference providerRef; // links to the provider
  final Timestamp? createdAt;

  ServiceModel({
    this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.category,
    required this.providerId,
    required this.providerRef,
    this.createdAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String? docId) {
    // Safely cast DocumentReference
    final providerRef = map['providerRef'] as DocumentReference;

    return ServiceModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'],
      category: map['category'] ?? '',
      providerId: map['providerId'] ?? '',
      providerRef: providerRef,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'category': category, // FIX: Included
      'providerId': providerId, // FIX: Included
      'providerRef': providerRef,
      'createdAt': createdAt,
    };
  }
}
