import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscriptionmodel.dart';

// --- Custom Exceptions ---
class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}

class SubscriptionPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Constants ---
  static const double _monthlySubscriptionPrice = 5000.0; // 5000 DZD per month
  static const double _appCommissionRate = 0.10; // 10% commission
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _appPaymentsCollection = 'app_payments';
  static const String _providersCollection =
      'users'; // Assuming providers are in 'users' collection

  // --- Subscription Plans ---
  static const Map<String, dynamic> _subscriptionPlans = {
    'basic': {
      'name': 'الباقة الأساسية',
      'price': 5000.0,
      'durationDays': 30,
      'features': ['الظهور في نتائج البحث', 'ملف تعريف أساسي'],
    },
    'premium': {
      'name': 'الباقة المميزة',
      'price': 8000.0,
      'durationDays': 30,
      'features': [
        'الظهور في نتائج البحث',
        'ملف تعريف مميز',
        'أعلى في الترتيب',
      ],
    },
    'vip': {
      'name': 'الباقة الذهبية',
      'price': 12000.0,
      'durationDays': 30,
      'features': [
        'الظهور في نتائج البحث',
        'ملف تعريف VIP',
        'أعلى الترتيب',
        'إعلان مميز',
      ],
    },
  };

  // --- Main Function: Provider Pays to Appear in Search ---
  Future<Map<String, dynamic>> subscribeForSearchVisibility({
    required String providerId,
    required DocumentReference providerRef,
    required String planType, // 'basic', 'premium', 'vip'
    required String paymentMethod, // 'cash' or 'eddahabia'
    Map<String, dynamic>? paymentDetails,
    String? notes,
  }) async {
    try {
      print('Processing subscription for search visibility: $planType');

      // Validate plan type
      if (!_subscriptionPlans.containsKey(planType)) {
        throw PaymentException('خطأ في نوع الباقة: $planType');
      }

      final plan = _subscriptionPlans[planType]!;
      final double amount = plan['price'] as double;
      final int durationDays = plan['durationDays'] as int;

      // Check if provider already has active subscription
      final bool hasActiveSubscription = await _checkActiveSubscription(
        providerId,
      );
      if (hasActiveSubscription) {
        throw PaymentException(
          'لديك اشتراك نشط بالفعل. يمكنك تجديده بعد انتهاء الصلاحية.',
        );
      }

      // Process payment for Eddahabia
      if (paymentMethod == 'eddahabia') {
        final bool paymentSuccess = await _processEddahabiaPayment(
          amount: amount,
          paymentDetails: paymentDetails ?? {},
        );

        if (!paymentSuccess) {
          throw PaymentException('فشل عملية الدفع عبر الدهابيا');
        }
      }

      // Create subscription record
      final subscription = await _createSearchSubscription(
        providerId: providerId,
        providerRef: providerRef,
        planType: planType,
        amount: amount,
        paymentMethod: paymentMethod,
        durationDays: durationDays,
        notes: notes,
      );

      // Update provider visibility status
      await _updateProviderSearchVisibility(providerId, true);

      // Record payment to app
      await _recordAppPayment(
        providerId: providerId,
        subscriptionId: subscription.subscriptionId!,
        planType: planType,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      print('Subscription completed successfully for provider: $providerId');

      return {
        'success': true,
        'subscriptionId': subscription.subscriptionId,
        'planType': planType,
        'planName': plan['name'],
        'amount': amount,
        'durationDays': durationDays,
        'paymentMethod': paymentMethod,
        'features': plan['features'],
        'message': 'تم تفعيل الاشتراك بنجاح! سيظهر مزود الخدمة في نتائج البحث.',
      };
    } catch (e) {
      print('Error in subscription process: $e');
      rethrow;
    }
  }

  // --- Check if Provider Can Appear in Search ---
  Future<bool> canProviderAppearInSearch(String providerId) async {
    try {
      final subscription = await getActiveSubscription(providerId);
      return subscription != null;
    } catch (e) {
      print('Error checking search visibility: $e');
      return false;
    }
  }

  // --- Get Active Subscription for Provider ---
  Future<SubscriptionModel?> getActiveSubscription(String providerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_subscriptionsCollection)
              .where('providerId', isEqualTo: providerId)
              .where('isActive', isEqualTo: true)
              .where('endDate', isGreaterThan: Timestamp.now())
              .orderBy('endDate', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SubscriptionModel.fromMap(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting active subscription: $e');
      return null;
    }
  }

  // --- Get All Subscription Plans ---
  Map<String, dynamic> getSubscriptionPlans() {
    return _subscriptionPlans;
  }

  // --- Renew Subscription ---
  Future<Map<String, dynamic>> renewSubscription({
    required String providerId,
    required DocumentReference providerRef,
    required String planType,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      // Get current subscription to check end date
      final currentSubscription = await getActiveSubscription(providerId);
      if (currentSubscription == null) {
        throw PaymentException('لا يوجد اشتراك نشط للتجديد');
      }

      // Process renewal
      return await subscribeForSearchVisibility(
        providerId: providerId,
        providerRef: providerRef,
        planType: planType,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
        notes: 'تجديد اشتراك',
      );
    } catch (e) {
      print('Error renewing subscription: $e');
      rethrow;
    }
  }

  // --- Cancel Subscription (Admin/Manual) ---
  Future<void> cancelSubscription(
    String subscriptionId, {
    String? reason,
  }) async {
    try {
      await _firestore
          .collection(_subscriptionsCollection)
          .doc(subscriptionId)
          .update({
            'isActive': false,
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancellationReason': reason ?? 'إلغاء يدوي',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Get provider ID to update visibility
      final doc =
          await _firestore
              .collection(_subscriptionsCollection)
              .doc(subscriptionId)
              .get();
      if (doc.exists) {
        final providerId = doc.data()!['providerId'] as String;
        await _updateProviderSearchVisibility(providerId, false);
      }

      print('Subscription cancelled: $subscriptionId');
    } catch (e) {
      print('Error cancelling subscription: $e');
      throw PaymentException('فشل في إلغاء الاشتراك');
    }
  }

  // --- Helper Methods ---

  Future<bool> _checkActiveSubscription(String providerId) async {
    final subscription = await getActiveSubscription(providerId);
    return subscription != null;
  }

  Future<SubscriptionModel> _createSearchSubscription({
    required String providerId,
    required DocumentReference providerRef,
    required String planType,
    required double amount,
    required String paymentMethod,
    required int durationDays,
    String? notes,
  }) async {
    final now = Timestamp.now();
    final endDate = Timestamp.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch + (durationDays * 24 * 60 * 60 * 1000),
    );

    final subscription = SubscriptionModel(
      subscriptionId: null,
      providerId: providerId,
      providerRef: providerRef,
      plan: planType,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'cash' ? 'pending' : 'paid',
      startDate: now,
      endDate: endDate,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      notes: notes ?? 'اشتراك للظهور في البحث - $planType',
    );

    final docRef = _firestore.collection(_subscriptionsCollection).doc();
    subscription.subscriptionId = docRef.id;
    await docRef.set(subscription.toMap());

    return subscription;
  }

  Future<List<SubscriptionModel>> getSubscriptionsByProvider(
    String providerId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_subscriptionsCollection)
              .where('providerId', isEqualTo: providerId)
              .orderBy('startDate', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting subscriptions: $e');
      throw PaymentException('Failed to fetch subscriptions');
    }
  }

  Future<void> _updateProviderSearchVisibility(
    String providerId,
    bool isVisible,
  ) async {
    await _firestore.collection(_providersCollection).doc(providerId).update({
      'isVisibleInSearch': isVisible,
      'searchVisibilityUpdatedAt': FieldValue.serverTimestamp(),
      ...(isVisible
          ? {'lastAppearedInSearch': FieldValue.serverTimestamp()}
          : {}),
    });
  }

  Future<void> _recordAppPayment({
    required String providerId,
    required String subscriptionId,
    required String planType,
    required double amount,
    required String paymentMethod,
  }) async {
    final docRef = _firestore.collection(_appPaymentsCollection).doc();
    final paymentData = {
      'paymentId': docRef.id,
      'providerId': providerId,
      'subscriptionId': subscriptionId,
      'planType': planType,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': 'completed',
      'purpose': 'search_visibility',
      'createdAt': FieldValue.serverTimestamp(),
      'processedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(paymentData);
  }

  // --- Eddahabia Payment Integration ---
  Future<bool> _processEddahabiaPayment({
    required double amount,
    required Map<String, dynamic> paymentDetails,
  }) async {
    const String apiUrl = 'https://api.eddahabia.com/payment';

    try {
      print('Processing Eddahabia payment for subscription: $amount DZD');

      final body = {
        'amount': amount,
        'currency': 'DZD',
        'merchantId': 'your_merchant_id',
        'apiKey': 'your_api_key',
        'description': 'اشتراك ظهور في البحث',
        'callbackUrl': 'your_callback_url',
        ...paymentDetails,
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer your_auth_token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool success = data['status'] == 'success';

        if (success) {
          print('Eddahabia subscription payment successful');
          return true;
        } else {
          print('Eddahabia payment failed: ${data['message']}');
          return false;
        }
      } else {
        print('Eddahabia API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Eddahabia payment error: $e');
      return false;
    }
  }

  // --- Subscription Management for Admin ---
  Future<List<SubscriptionModel>> getAllActiveSubscriptions() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_subscriptionsCollection)
              .where('isActive', isEqualTo: true)
              .where('endDate', isGreaterThan: Timestamp.now())
              .orderBy('endDate')
              .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active subscriptions: $e');
      return [];
    }
  }

  Future<List<SubscriptionModel>> getExpiringSubscriptions(
    int daysBeforeExpiry,
  ) async {
    try {
      final expiryThreshold = Timestamp.fromMillisecondsSinceEpoch(
        DateTime.now()
            .add(Duration(days: daysBeforeExpiry))
            .millisecondsSinceEpoch,
      );

      final querySnapshot =
          await _firestore
              .collection(_subscriptionsCollection)
              .where('isActive', isEqualTo: true)
              .where('endDate', isLessThan: expiryThreshold)
              .where('endDate', isGreaterThan: Timestamp.now())
              .orderBy('endDate')
              .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting expiring subscriptions: $e');
      return [];
    }
  }

  // --- Notify Provider About Expiry ---
  Future<void> notifySubscriptionExpiry(String providerId, int daysLeft) async {
    // Here you would integrate with your notification service
    print(
      'Notifying provider $providerId: subscription expires in $daysLeft days',
    );

    // Example: Send push notification
    // await NotificationService().sendNotification(
    //   userId: providerId,
    //   title: 'اشتراكك على وشك الانتهاء',
    //   body: 'يبقى $daysLeft يوم على انتهاء اشتراكك. جدد الآن لتبقى ظاهراً في البحث.',
    // );
  }
}
