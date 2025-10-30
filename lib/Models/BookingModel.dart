import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  String? id;
  String clientId;
  String providerId;
  DateTime dateTime;
  String status; // "pending", "confirmed", "completed", "cancelled"
  String notes;

  BookingModel({
    this.id,
    required this.clientId,
    required this.providerId,
    required this.dateTime,
    this.status = 'pending',
    this.notes = '',
  });

  /// Convert Firestore Document to BookingModel
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      clientId: map['clientId'] ?? '',
      providerId: map['providerId'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      notes: map['notes'] ?? '',
    );
  }

  /// Convert BookingModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'providerId': providerId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'notes': notes,
    };
  }

  /// CopyWith method for updating fields immutably
  BookingModel copyWith({
    String? id,
    String? clientId,
    String? providerId,
    DateTime? dateTime,
    String? status,
    String? notes,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      providerId: providerId ?? this.providerId,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
