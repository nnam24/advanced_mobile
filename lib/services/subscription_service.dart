import 'dart:async';
import 'dart:convert';
import 'package:final_application/models/user_subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _subscriptionKey = 'user_subscription';

  // Stream controller to broadcast subscription changes
  final _subscriptionController =
      StreamController<UserSubscription>.broadcast();

  // Singleton pattern with proper initialization
  static SubscriptionService? _instance;
  static SubscriptionService get instance {
    _instance ??= SubscriptionService._internal();
    return _instance!;
  }

  factory SubscriptionService() => instance;

  SubscriptionService._internal();

  // The current subscription
  UserSubscription _subscription = const UserSubscription();

  // Stream to listen for subscription changes
  Stream<UserSubscription> get subscriptionStream =>
      _subscriptionController.stream;

  // Current subscription
  UserSubscription get subscription => _subscription;

  // Initialize the service
  Future<void> init() async {
    await _loadSubscription();
  }

  // Load subscription from local storage
  Future<void> _loadSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? subscriptionJson = prefs.getString(_subscriptionKey);

      if (subscriptionJson != null) {
        try {
          final Map<String, dynamic> decoded = Map<String, dynamic>.from(
            json.decode(subscriptionJson) as Map,
          );
          _subscription = UserSubscription.fromJson(decoded);
          _subscriptionController.add(_subscription);
        } catch (e) {
          print('Error parsing subscription data: $e');
        }
      }
    } catch (e) {
      print('Error loading subscription: $e');
    }
  }

  // Save subscription to local storage
  Future<void> _saveSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _subscriptionKey,
        json.encode(_subscription.toJson()),
      );
      _subscriptionController.add(_subscription);
    } catch (e) {
      print('Error saving subscription: $e');
    }
  }

  // Upgrade to Pro
  Future<void> upgradeToPro({DateTime? expiryDate}) async {
    _subscription = _subscription.copyWith(
      type: SubscriptionType.pro,
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
    );
    await _saveSubscription();
  }

  // Downgrade to Free
  Future<void> downgradeToFree() async {
    _subscription = _subscription.copyWith(
      type: SubscriptionType.free,
      expiryDate: null,
    );
    await _saveSubscription();
  }

  // Add tokens to account
  Future<void> addTokens(int amount) async {
    if (_subscription.type == SubscriptionType.free) {
      _subscription = _subscription.copyWith(
        tokens: _subscription.tokens + amount,
      );
      await _saveSubscription();
    }
  }

  // Use a token
  Future<bool> useToken() async {
    if (_subscription.isProActive) {
      return true; // Pro users don't consume tokens
    }

    if (_subscription.tokens <= 0) {
      return false; // No tokens available
    }

    _subscription = _subscription.copyWith(tokens: _subscription.tokens - 1);
    await _saveSubscription();
    return true;
  }

  void dispose() {
    _subscriptionController.close();
  }
}
