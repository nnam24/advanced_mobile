import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_info.dart';
import '../models/token_usage.dart';

class SubscriptionService {
  static const String baseUrl = 'https://api.dev.jarvis.cx/api/v1';

  // Get auth token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get current subscription info
  Future<SubscriptionInfo> getCurrentSubscription() async {
    final token = await _getAuthToken();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/me'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        // Create the subscription info from the response
        final subscriptionInfo = SubscriptionInfo.fromJson(responseData);

        // Map the actual plan name based on the rules
        // This doesn't change the original data, just how we interpret it
        String mappedPlanName = 'basic';

        if (subscriptionInfo.name == 'starter') {
          if (subscriptionInfo.billingPeriod == 'annually') {
            mappedPlanName = 'pro';
          } else if (subscriptionInfo.billingPeriod == 'monthly') {
            mappedPlanName = 'starter';
          }
        }

        // Log the mapping for debugging
        print('Original plan: ${subscriptionInfo.name}, billing period: ${subscriptionInfo.billingPeriod}');
        print('Mapped to plan: $mappedPlanName');

        // Return a new instance with the mapped plan name
        return SubscriptionInfo(
          name: mappedPlanName,
          dailyTokens: subscriptionInfo.dailyTokens,
          monthlyTokens: subscriptionInfo.monthlyTokens,
          annuallyTokens: subscriptionInfo.annuallyTokens,
          price: subscriptionInfo.price,
          billingPeriod: subscriptionInfo.billingPeriod,
          startAt: subscriptionInfo.startAt,
          endAt: subscriptionInfo.endAt,
          trial: subscriptionInfo.trial,
        );
      } else {
        // If API fails, return a basic plan as default
        return SubscriptionInfo(
          name: 'basic',
          dailyTokens: 50,
          monthlyTokens: 0,
          annuallyTokens: 0,
          price: 0,
          billingPeriod: 'free',
          startAt: DateTime.now(),
          endAt: DateTime.now().add(const Duration(days: 365)),
          trial: false,
        );
      }
    } catch (e) {
      print('Error fetching subscription info: $e');
      // Return a basic plan as default in case of error
      return SubscriptionInfo(
        name: 'basic',
        dailyTokens: 50,
        monthlyTokens: 0,
        annuallyTokens: 0,
        price: 0,
        billingPeriod: 'free',
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(days: 365)),
        trial: false,
      );
    }
  }

  // Get token usage
  Future<TokenUsage> getTokenUsage() async {
    final token = await _getAuthToken();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tokens/usage'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        return TokenUsage.fromJson(responseData);
      } else {
        // If API fails, return empty usage
        return TokenUsage.empty();
      }
    } catch (e) {
      print('Error fetching token usage: $e');
      // Return empty usage in case of error
      return TokenUsage.empty();
    }
  }

  // Subscribe to a plan
  Future<String> subscribeToPlan(String plan, String period) async {
    final token = await _getAuthToken();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json',
    };

    try {
      // For testing purposes, use a direct Stripe checkout URL that we know works
      // This is a temporary solution until the API is fixed
      // if (plan == 'starter' && period == 'monthly') {
      //   return 'https://buy.stripe.com/test_28o5mz7Wd0Yk1qw000';
      // } else if (plan == 'starter' && period == 'annually') {
      //   return 'https://buy.stripe.com/test_28o5mz7Wd0Yk1qw000';
      // }

      // If we're not using test URLs, proceed with the API call
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/subscribe?plan=$plan&period=$period'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // The API is returning the checkout URL directly as a string, not as JSON
        final checkoutUrl = response.body.trim();

        // Log the URL for debugging
        print('Original checkout URL: $checkoutUrl');

        // If the URL contains a fragment (#), remove it and everything after
        // as it might be causing issues with URL launching
        // String cleanUrl = checkoutUrl;
        // if (checkoutUrl.contains('#')) {
        //   cleanUrl = checkoutUrl.split('#')[0];
        //   print('Cleaned URL (removed fragment): $cleanUrl');
        // }

        return checkoutUrl;
      } else {
        throw Exception('Failed to subscribe to plan. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error subscribing to plan: $e');
      throw Exception('Error subscribing to plan: $e');
    }
  }
}
