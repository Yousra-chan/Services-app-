// --- Subscription Plan Model ---
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final List<String> features;
  final String description;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.description,
  });
}

// --- Provider Subscription Model ---
class ProviderSubscription {
  final String subscriptionId;
  final String planType;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'expired', 'cancelled'
  final String paymentMethod;

  ProviderSubscription({
    required this.subscriptionId,
    required this.planType,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentMethod,
  });
}

// --- Transaction Model ---
class Transaction {
  final String id;
  final String description;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String status; // 'completed', 'pending', 'failed'
  final String type; // 'subscription', 'withdrawal', 'refund'

  Transaction({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.status,
    required this.type,
  });
}

// --- Available Subscription Plans ---
final List<SubscriptionPlan> subscriptionPlans = [
  SubscriptionPlan(
    id: 'basic',
    name: 'Basic Package',
    price: 5000.0,
    durationDays: 30,
    features: [
      'Appear in search results',
      'Basic profile',
      'Contact information visible',
    ],
    description: 'Essential visibility for your business',
  ),
  SubscriptionPlan(
    id: 'premium',
    name: 'Premium Package',
    price: 8000.0,
    durationDays: 30,
    features: [
      'Appear in search results',
      'Premium profile badge',
      'Higher ranking in search',
      'Priority customer support',
    ],
    description: 'Enhanced visibility and priority placement',
  ),
  SubscriptionPlan(
    id: 'vip',
    name: 'VIP Package',
    price: 12000.0,
    durationDays: 30,
    features: [
      'Appear in search results',
      'VIP profile badge',
      'Top ranking in search',
      'Featured listing',
      'Premium customer support',
      'Analytics dashboard',
    ],
    description: 'Maximum visibility and premium features',
  ),
];
