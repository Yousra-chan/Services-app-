import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'payment_constants.dart';
import 'package:myapp/screens/profile/profile_constants.dart';

// Builds a standard section title for the payment page
Widget buildPaymentSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 25, bottom: 10, left: 30, right: 20),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: kMutedTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: 'Exo2',
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}

// Reusable card container for action/list groups (similar to buildActionCard)
Widget buildPaymentCard({required List<Widget> children}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: kCardBackgroundColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: kSoftShadowColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

// Builds a tile for a single payment method (e.g., Credit Card)
Widget buildPaymentMethodTile(PaymentMethod method, bool isLast) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, top: 2),
    child: Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(method.icon, color: kPrimaryBlue, size: 24),
          ),
          title: Text(
            method.title,
            style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Exo2',
            ),
          ),
          subtitle: Text(
            '**** ${method.lastFourDigits} (${method.type})',
            style: const TextStyle(
              color: kMutedTextColor,
              fontSize: 12,
              fontFamily: 'Exo2',
            ),
          ),
          trailing: const Icon(CupertinoIcons.forward, color: kMutedTextColor),
          onTap: () {
            // Handle method details tap
          },
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 75, // Aligns with the title text
            color: Color.fromARGB(255, 230, 230, 230),
          ),
      ],
    ),
  );
}

// Builds a tile for a single transaction in the history
Widget buildTransactionTile(Transaction transaction) {
  final Color amountColor =
      transaction.isCredit ? kOnlineStatusGreen : kDangerColor;
  final String sign = transaction.isCredit ? '+' : '-';

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: amountColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          transaction.isCredit
              ? CupertinoIcons.arrow_down_left
              : CupertinoIcons.arrow_up_right,
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(
          color: kDarkTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Exo2',
        ),
      ),
      subtitle: Text(
        transaction.date,
        style: const TextStyle(
          color: kMutedTextColor,
          fontSize: 12,
          fontFamily: 'Exo2',
        ),
      ),
      trailing: Text(
        '$sign\$${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: amountColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Exo2',
        ),
      ),
    ),
  );
}
