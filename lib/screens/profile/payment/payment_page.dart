import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/profile/profile_constants.dart';
import 'payment_constants.dart'; // For accessing data models
import 'payment_widgets.dart'; // For accessing custom widgets

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        // Custom App Bar style
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
          "Payment & Billing",
          style: TextStyle(
            color: kLightTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),

            // --- 1. Payment Methods Section ---
            buildPaymentSectionTitle("PAYMENT METHODS"),
            buildPaymentCard(
              children: [
                // Map the dummy data to tiles
                ...dummyPaymentMethods.asMap().entries.map((entry) {
                  int index = entry.key;
                  PaymentMethod method = entry.value;
                  return buildPaymentMethodTile(
                    method,
                    index == dummyPaymentMethods.length - 1, // isLast check
                  );
                }),

                // Add new card/method action button
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 5,
                  ),
                  leading: const Icon(
                    CupertinoIcons.add_circled_solid,
                    color: kPrimaryBlue,
                  ),
                  title: const Text(
                    "Add New Method",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  onTap: () {
                    // Navigate to add payment method screen
                  },
                ),
              ],
            ),

            // --- 2. Recent Transactions Section ---
            buildPaymentSectionTitle("RECENT TRANSACTIONS"),
            buildPaymentCard(
              children: [
                // Map the dummy data to transaction tiles
                ...dummyTransactions.asMap().entries.map((entry) {
                  Transaction transaction = entry.value;
                  return Column(
                    children: [
                      buildTransactionTile(transaction),
                      // Add a divider between transactions, but not after the last one
                      if (entry.key < dummyTransactions.length - 1)
                        const Divider(
                          height: 1,
                          indent: 75,
                          endIndent: 20,
                          color: Color.fromARGB(255, 230, 230, 230),
                        ),
                    ],
                  );
                }),

                // See All Transactions action
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextButton(
                    onPressed: () {
                      // Navigate to full transaction history
                    },
                    child: const Text(
                      "See Full History",
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
