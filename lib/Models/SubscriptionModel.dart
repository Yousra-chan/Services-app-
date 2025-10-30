import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  String? subscriptionId;
  final String providerId;
  final DocumentReference providerRef;
  final String plan;
  final double amount;
  final String paymentMethod; // "cash" | "eddahabia"
  final String paymentStatus; // "pending" | "paid" | "failed"
  final Timestamp startDate;
  final Timestamp endDate;
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? transactionId;
  final String? notes;

  SubscriptionModel({
    this.subscriptionId,
    required this.providerId,
    required this.providerRef,
    required this.plan,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.transactionId,
    this.notes,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String? docId) {
    return SubscriptionModel(
      subscriptionId: docId,
      providerId: map['providerId'] ?? '',
      providerRef: map['providerRef'] as DocumentReference,
      plan: map['plan'] ?? '',
      amount: (map['amount'] is num) ? map['amount'].toDouble() : 0.0,
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      startDate: map['startDate'] as Timestamp,
      endDate: map['endDate'] as Timestamp,
      isActive: map['isActive'] ?? false,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
      transactionId: map['transactionId'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'providerRef': providerRef,
      'plan': plan,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'transactionId': transactionId,
      'notes': notes,
    };
  }

  SubscriptionModel copyWith({
    String? subscriptionId,
    String? providerId,
    DocumentReference? providerRef,
    String? plan,
    double? amount,
    String? paymentMethod,
    String? paymentStatus,
    Timestamp? startDate,
    Timestamp? endDate,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? transactionId,
    String? notes,
  }) {
    return SubscriptionModel(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      providerId: providerId ?? this.providerId,
      providerRef: providerRef ?? this.providerRef,
      plan: plan ?? this.plan,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
    );
  }
}
