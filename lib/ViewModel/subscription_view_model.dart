import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/payment_service.dart';
import '../models/subscriptionmodel.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final SubscriptionPaymentService _subscriptionService =
      SubscriptionPaymentService();

  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _subscriptionPlans;

  // Getters
  List<SubscriptionModel> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get subscriptionPlans => _subscriptionPlans;

  /// Initialize and load subscription plans
  Future<void> initialize() async {
    _subscriptionPlans = _subscriptionService.getSubscriptionPlans();
    notifyListeners();
  }

  /// Purchase subscription for search visibility
  Future<Map<String, dynamic>> purchaseSubscription({
    required String providerId,
    required DocumentReference providerRef,
    required String planType,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _subscriptionService.subscribeForSearchVisibility(
        providerId: providerId,
        providerRef: providerRef,
        planType: planType,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
        notes: notes,
      );

      return result;
    } catch (e) {
      _errorMessage = 'فشل في شراء الاشتراك: $e';
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if provider can appear in search results
  Future<bool> canAppearInSearch(String providerId) async {
    try {
      return await _subscriptionService.canProviderAppearInSearch(providerId);
    } catch (e) {
      _errorMessage = 'فشل في التحقق من حالة الظهور في البحث: $e';
      return false;
    }
  }

  /// Get active subscription for provider
  Future<SubscriptionModel?> getActiveSubscription(String providerId) async {
    try {
      return await _subscriptionService.getActiveSubscription(providerId);
    } catch (e) {
      _errorMessage = 'فشل في جلب الاشتراك النشط: $e';
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(
    String subscriptionId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _subscriptionService.cancelSubscription(
        subscriptionId,
        reason: reason,
      );
      return true;
    } catch (e) {
      _errorMessage = 'فشل في إلغاء الاشتراك: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get all active subscriptions (admin feature)
  Future<List<SubscriptionModel>> getAllActiveSubscriptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final subscriptions =
          await _subscriptionService.getAllActiveSubscriptions();
      return subscriptions;
    } catch (e) {
      _errorMessage = 'فشل في جلب الاشتراكات النشطة: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get expiring subscriptions
  Future<List<SubscriptionModel>> getExpiringSubscriptions(
    int daysBeforeExpiry,
  ) async {
    try {
      return await _subscriptionService.getExpiringSubscriptions(
        daysBeforeExpiry,
      );
    } catch (e) {
      _errorMessage = 'فشل في جلب الاشتراكات المنتهية: $e';
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset view model state
  void reset() {
    _subscriptions = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get subscription plan details
  Map<String, dynamic>? getPlanDetails(String planType) {
    return _subscriptionPlans?[planType];
  }
}
