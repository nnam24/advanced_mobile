import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';
import '../providers/auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<SubscriptionPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String get error => _error;

  SubscriptionProvider() {
    _initializePlans();
  }

  void _initializePlans() {
    _plans = [
      SubscriptionPlan(
        id: 'free',
        name: 'Free',
        price: 0.0,
        billingCycle: 'month',
        features: [
          '1,000 tokens per month',
          'Access to Claude 3.5 Sonnet',
          'Basic chat functionality',
          'Standard response time',
        ],
        tokenAllowance: 1000,
        modelLimit: 1,
        hasAdvancedFeatures: false,
      ),
      SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        price: 9.99,
        billingCycle: 'month',
        features: [
          '10,000 tokens per month',
          'Access to all AI models',
          'Advanced chat features',
          'Priority response time',
          'Knowledge base integration',
        ],
        tokenAllowance: 10000,
        modelLimit: 3,
        hasAdvancedFeatures: true,
      ),
      SubscriptionPlan(
        id: 'enterprise',
        name: 'Enterprise',
        price: 29.99,
        billingCycle: 'month',
        features: [
          'Unlimited tokens',
          'Access to all AI models',
          'All advanced features',
          'Fastest response time',
          'Custom AI bot creation',
          'Team collaboration',
          'Priority support',
        ],
        tokenAllowance: 100000,
        modelLimit: 10,
        hasAdvancedFeatures: true,
      ),
    ];
  }

  // Get plan by ID
  SubscriptionPlan? getPlanById(String planId) {
    try {
      return _plans.firstWhere((plan) => plan.id == planId);
    } catch (e) {
      return null;
    }
  }

  // Subscribe to a plan
  Future<bool> subscribeToPlan(String planId) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, you would call an API here
      final plan = getPlanById(planId);
      if (plan == null) {
        _error = 'Plan not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update user's plan (this would be done by the backend in a real app)
      // For demo purposes, we'll just update the AuthProvider
      // This is a simplified implementation
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, you would call an API here
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get token usage for current billing cycle
  Future<Map<String, dynamic>> getTokenUsage() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      final usage = {
        'used': 450,
        'total': 1000,
        'percentage': 45.0,
        'resetDate': DateTime.now().add(const Duration(days: 15)),
      };

      _isLoading = false;
      notifyListeners();
      return usage;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'used': 0,
        'total': 0,
        'percentage': 0.0,
        'resetDate': DateTime.now(),
      };
    }
  }

  // Purchase additional tokens
  Future<bool> purchaseTokens(int amount) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, you would call an API here
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}

