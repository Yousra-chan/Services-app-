import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'payment_constants.dart' as payment_constants;
import 'payment_widgets.dart';
import 'package:myapp/services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final SubscriptionPaymentService _paymentService =
      SubscriptionPaymentService();
  payment_constants.ProviderSubscription? _currentSubscription;
  final List<payment_constants.Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      // TODO: Replace with actual provider ID from your auth system
      final String providerId = 'current_provider_id';

      // Load current subscription
      final subscriptionModel = await _paymentService.getActiveSubscription(
        providerId,
      );

      // Convert SubscriptionModel to ProviderSubscription
      if (subscriptionModel != null) {
        setState(() {
          _currentSubscription = payment_constants.ProviderSubscription(
            subscriptionId: subscriptionModel.subscriptionId!,
            planType: subscriptionModel.plan,
            amount: subscriptionModel.amount,
            startDate: subscriptionModel.startDate.toDate(),
            endDate: subscriptionModel.endDate.toDate(),
            status: subscriptionModel.isActive ? 'active' : 'expired',
            paymentMethod: subscriptionModel.paymentMethod,
          );
        });
      }

      // Load transaction history (you'll need to implement this method in your service)
      // final transactions = await _paymentService.getProviderTransactions(providerId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading provider data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToPlan(payment_constants.SubscriptionPlan plan) async {
    try {
      // TODO: Replace with actual provider data from your auth system
      final String providerId = 'current_provider_id';
      final DocumentReference providerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(providerId);

      final result = await _paymentService.subscribeForSearchVisibility(
        providerId: providerId,
        providerRef: providerRef,
        planType: plan.id,
        paymentMethod: 'eddahabia',
        paymentDetails: {
          'customerEmail': 'provider@example.com', // TODO: Get from user data
          'customerName': 'Provider Name', // TODO: Get from user data
        },
      );

      if (result['success'] == true) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: kOnlineStatusGreen,
            ),
          );

          // Reload data
          _loadProviderData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription failed: ${e.toString()}'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: kLightTextColor,
            size: 28,
          ),
        ),
        title: const Text(
          "Subscriptions & Payments",
          style: TextStyle(
            color: kLightTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

                    // --- 1. Current Subscription Section ---
                    buildPaymentSectionTitle("CURRENT SUBSCRIPTION"),
                    buildPaymentCard(
                      children: [
                        buildActiveSubscriptionTile(_currentSubscription),
                      ],
                    ),

                    // --- 2. Available Subscription Plans ---
                    buildPaymentSectionTitle("AVAILABLE PLANS"),
                    ...payment_constants.subscriptionPlans.map(
                      (plan) => buildSubscriptionPlanCard(
                        plan,
                        () => _subscribeToPlan(plan),
                      ),
                    ),

                    // --- 3. Recent Transactions Section ---
                    if (_transactions.isNotEmpty) ...[
                      buildPaymentSectionTitle("RECENT TRANSACTIONS"),
                      buildPaymentCard(
                        children: [
                          ..._transactions.asMap().entries.map((entry) {
                            final transaction = entry.value;
                            return Column(
                              children: [
                                buildTransactionTile(transaction),
                                if (entry.key < _transactions.length - 1)
                                  const Divider(
                                    height: 1,
                                    indent: 75,
                                    endIndent: 20,
                                    color: Color.fromARGB(255, 230, 230, 230),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],

                    // --- 4. No Transactions Placeholder ---
                    if (_transactions.isEmpty) ...[
                      buildPaymentSectionTitle("TRANSACTION HISTORY"),
                      buildPaymentCard(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: kMutedTextColor,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    color: kMutedTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Exo2',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Your subscription payments will appear here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kMutedTextColor,
                                    fontSize: 14,
                                    fontFamily: 'Exo2',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }
}
