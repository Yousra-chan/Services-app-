import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/ServicesModel.dart';
import 'package:myapp/models/UserModel.dart';

class ProviderModel {
  final UserModel user;
  Service? primaryService; // Add this to store the main service

  ProviderModel({required this.user, this.primaryService});

  String? get uid => user.uid;
  String get name => user.name;
  String get profession => user.profession ?? '';
  String get phone => user.phone;
  String get whatsapp => user.phone;
  String? get photoUrl => user.photoUrl;
  GeoPoint? get location => user.location;
  String get address => user.address;
  double get rating => user.rating;
  bool get subscriptionActive => user.subscriptionActive;
  String get email => user.email;
  List<String> get serviceIds => user.serviceIds;
  List<String> get chatIds => user.chatIds;

  // Get description from primary service
  String get description =>
      primaryService?.description ?? 'No service description available.';

  // These methods extract info from address
  String get wilaya => _extractWilayaFromAddress(user.address) ?? '';
  String get commune => _extractCommuneFromAddress(user.address) ?? '';

  String? _extractWilayaFromAddress(String address) {
    if (address.isEmpty) return null;

    final wilayas = [
      'Alger',
      'Boumerdès',
      'Blida',
      'Oran',
      'Tizi Ouzou',
      'Constantine'
    ];

    for (var wilaya in wilayas) {
      if (address.toLowerCase().contains(wilaya.toLowerCase())) {
        return wilaya;
      }
    }

    return null;
  }

  String? _extractCommuneFromAddress(String address) {
    if (address.isEmpty) return null;

    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }

    return null;
  }

  // Factory method that also fetches the primary service
  static Future<ProviderModel> fromUserWithService(UserModel user) async {
    Service? primaryService;

    if (user.serviceIds.isNotEmpty) {
      try {
        final serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(user.serviceIds.first)
            .get();

        if (serviceDoc.exists) {
          primaryService = Service.fromMap({
            ...serviceDoc.data() as Map<String, dynamic>,
            'id': serviceDoc.id,
          });
        }
      } catch (e) {
        print('Error fetching service: $e');
      }
    }

    return ProviderModel(user: user, primaryService: primaryService);
  }

  // Existing factory for backward compatibility
  factory ProviderModel.fromUser(UserModel user) {
    return ProviderModel(user: user);
  }

  Map<String, dynamic> toMap() {
    return user.toMap();
  }
}
