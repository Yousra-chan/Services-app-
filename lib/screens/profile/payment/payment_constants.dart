import 'package:flutter/material.dart';

// --- Global Constants (Already defined in profile_constants.dart, importing is sufficient) ---
// Note: We don't redefine the colors here, we just use them in the pages/widgets.

// --- Dummy Payment Data ---

// Model for a single payment card/method
class PaymentMethod {
  final String title;
  final String lastFourDigits;
  final String type; // e.g., 'Visa', 'MasterCard', 'PayPal'
  final IconData icon;

  PaymentMethod({
    required this.title,
    required this.lastFourDigits,
    required this.type,
    required this.icon,
  });
}

// Model for a single transaction
class Transaction {
  final String description;
  final String date;
  final double amount;
  final bool isCredit; // true if incoming, false if outgoing (debit)

  Transaction({
    required this.description,
    required this.date,
    required this.amount,
    required this.isCredit,
  });
}

final List<PaymentMethod> dummyPaymentMethods = [
  PaymentMethod(
    title: "Primary Debit Card",
    lastFourDigits: "8045",
    type: "Visa",
    icon: Icons.credit_card_rounded,
  ),
  PaymentMethod(
    title: "Secondary Credit",
    lastFourDigits: "3109",
    type: "MasterCard",
    icon: Icons.credit_card_rounded,
  ),
  PaymentMethod(
    title: "PayPal Account",
    lastFourDigits: "p******l",
    type: "PayPal",
    icon: Icons.payment_rounded,
  ),
];

final List<Transaction> dummyTransactions = [
  Transaction(
    description: "Subscription Renewal",
    date: "Oct 1, 2025",
    amount: 19.99,
    isCredit: false,
  ),
  Transaction(
    description: "Freelance Payment",
    date: "Sep 28, 2025",
    amount: 450.00,
    isCredit: true,
  ),
  Transaction(
    description: "App Store Purchase",
    date: "Sep 25, 2025",
    amount: 4.99,
    isCredit: false,
  ),
  Transaction(
    description: "ATM Withdrawal",
    date: "Sep 20, 2025",
    amount: 100.00,
    isCredit: false,
  ),
];
