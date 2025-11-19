import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'payment_constants.dart' as payment_constants;
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

// Reusable card container for action/list groups
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

// Builds a subscription plan card
Widget buildSubscriptionPlanCard(
  payment_constants.SubscriptionPlan plan,
  VoidCallback onSubscribe,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      border: Border.all(color: kPrimaryBlue.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: kDarkTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${plan.price.toStringAsFixed(0)} DZD',
                      style: const TextStyle(
                        color: kPrimaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.description,
                style: TextStyle(
                  color: kMutedTextColor,
                  fontSize: 14,
                  fontFamily: 'Exo2',
                ),
              ),
              const SizedBox(height: 16),
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: kOnlineStatusGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: kDarkTextColor,
                            fontSize: 14,
                            fontFamily: 'Exo2',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 1,
          color: kSoftShadowColor.withOpacity(0.2),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: kLightTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Subscribe with Eddahabia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Exo2',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// Builds a tile for current active subscription
Widget buildActiveSubscriptionTile(
  payment_constants.ProviderSubscription? subscription,
) {
  if (subscription == null) {
    return const ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      leading: Icon(Icons.error_outline, color: kDangerColor, size: 24),
      title: Text(
        'No Active Subscription',
        style: TextStyle(
          color: kDarkTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Exo2',
        ),
      ),
      subtitle: Text(
        'Subscribe to appear in search results',
        style: TextStyle(
          color: kMutedTextColor,
          fontSize: 14,
          fontFamily: 'Exo2',
        ),
      ),
    );
  }

  final bool isActive = subscription.status == 'active';
  final Color statusColor = isActive ? kOnlineStatusGreen : kDangerColor;
  final daysLeft = subscription.endDate.difference(DateTime.now()).inDays;

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    leading: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isActive ? Icons.verified : Icons.warning,
        color: statusColor,
        size: 24,
      ),
    ),
    title: Text(
      '${subscription.planType.toUpperCase()} Subscription',
      style: const TextStyle(
        color: kDarkTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Exo2',
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${subscription.amount.toStringAsFixed(0)} DZD • ${subscription.paymentMethod}',
          style: TextStyle(
            color: kMutedTextColor,
            fontSize: 14,
            fontFamily: 'Exo2',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isActive
              ? 'Expires in $daysLeft days'
              : 'Expired on ${_formatDate(subscription.endDate)}',
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Exo2',
          ),
        ),
      ],
    ),
    trailing: Icon(CupertinoIcons.forward, color: kMutedTextColor),
  );
}

// Builds a tile for a single transaction
Widget buildTransactionTile(payment_constants.Transaction transaction) {
  final Color amountColor =
      transaction.isCredit ? kOnlineStatusGreen : kDangerColor;
  final Color statusColor =
      transaction.status == 'completed'
          ? kOnlineStatusGreen
          : transaction.status == 'pending'
          ? Colors.orange
          : kDangerColor;

  final String sign = transaction.isCredit ? '+' : '-';

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: amountColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        transaction.type == 'subscription'
            ? Icons.subscriptions
            : transaction.isCredit
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
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDate(transaction.date),
          style: const TextStyle(
            color: kMutedTextColor,
            fontSize: 12,
            fontFamily: 'Exo2',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          transaction.status.toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Exo2',
          ),
        ),
      ],
    ),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$sign${transaction.amount.toStringAsFixed(0)} DZD',
          style: TextStyle(
            color: amountColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Exo2',
          ),
        ),
        Text(
          transaction.type,
          style: TextStyle(
            color: kMutedTextColor,
            fontSize: 11,
            fontFamily: 'Exo2',
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
