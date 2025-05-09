import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/subscription_plan.dart';
import '../models/subscription_info.dart';
import '../models/token_usage.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingTokens = false;
  String _error = '';
  SubscriptionInfo? _currentSubscription;
  TokenUsage? _tokenUsage;
  final SubscriptionService _subscriptionService = SubscriptionService();
  Timer? _tokenRefreshTimer;
  final int _tokenRefreshInterval = 5; // Refresh interval in seconds

  // Updated plans based on the image
  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Basic',
      price: 0,
      billingCycle: 'Free',
      features: [
        'AI Chat Model: GPT-3.5',
        'AI Action Injection',
        'Select Text for AI Action',
        '50 free queries per day',
        'AI Reading Assistant',
        'Real-time Web Access',
        'AI Writing Assistant',
        'AI Pro Search',
      ],
    ),
    SubscriptionPlan(
      id: 'starter',
      name: 'Starter',
      price: 9.99,
      billingCycle: 'month',
      trialPeriod: '1-month Free Trial',
      features: [
        'AI Chat Models: GPT-3.5 & GPT-4.0/Turbo & Gemini Pro & Gemini Ultra',
        'AI Action Injection',
        'Select Text for AI Action',
        'Unlimited queries per month',
        'AI Reading Assistant',
        'Real-time Web Access',
        'AI Writing Assistant',
        'AI Pro Search',
        'Jira Copilot Assistant',
        'Github Copilot Assistant',
        'No request limits during high-traffic',
      ],
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro Annually',
      price: 79.99,
      billingCycle: 'year',
      trialPeriod: '1-month Free Trial',
      savePercentage: 'SAVE 33% ON ANNUAL PLAN!',
      isPopular: true,
      features: [
        'AI Chat Models: GPT-3.5 & GPT-4.0/Turbo & Gemini Pro & Gemini Ultra',
        'AI Action Injection',
        'Select Text for AI Action',
        'Unlimited queries per year',
        'AI Reading Assistant',
        'Real-time Web Access',
        'AI Writing Assistant',
        'AI Pro Search',
        'Jira Copilot Assistant',
        'Github Copilot Assistant',
        'No request limits during high-traffic',
      ],
    ),
  ];

  List<SubscriptionPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  bool get isLoadingTokens => _isLoadingTokens;
  String get error => _error;
  SubscriptionInfo? get currentSubscription => _currentSubscription;
  TokenUsage? get tokenUsage => _tokenUsage;

  // Add getters for token usage
  bool get hasUnlimitedTokens => _tokenUsage?.unlimited ?? false;
  int get availableTokens => _tokenUsage?.availableTokens ?? 0;
  int get totalTokens => _tokenUsage?.totalTokens ?? 0;

  // Add token availability percentage getter
  double get tokenAvailabilityPercentage {
    if (hasUnlimitedTokens) return 1.0; // Full bar for unlimited
    if (totalTokens <= 0) return 0.0;
    return availableTokens / totalTokens;
  }

  // Add hasTokens getter
  bool get hasTokens => hasUnlimitedTokens || availableTokens > 0;

  // Fetch current subscription info
  Future<void> fetchCurrentSubscription() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      _currentSubscription = subscription;
      _isLoading = false;
      notifyListeners();

      // After fetching subscription, also fetch token usage
      await fetchTokenUsage();

      // Start the token refresh timer
      startTokenRefreshTimer();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch token usage
  Future<void> fetchTokenUsage() async {
    print('Fetching token usage at ${DateTime.now()}');
    _isLoadingTokens = true;
    notifyListeners();

    try {
      final usage = await _subscriptionService.getTokenUsage();
      _tokenUsage = usage;
      _isLoadingTokens = false;
      notifyListeners();
      print('Token usage updated: ${usage.availableTokens}/${usage.totalTokens} (unlimited: ${usage.unlimited})');
    } catch (e) {
      print('Error fetching token usage: $e');
      _isLoadingTokens = false;
      notifyListeners();
    }
  }

  // Subscribe to a plan
  Future<bool> subscribeToPlan(String planId, String period) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final checkoutUrl = await _subscriptionService.subscribeToPlan(planId, period);

      // Make sure the URL is valid
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Received empty checkout URL');
      }

      // Print the URL for debugging
      print('Checkout URL: $checkoutUrl');

      // Try different launch modes if one fails
      bool launched = false;

      // First try with external application mode
      try {
        final Uri uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        print('Failed to launch in external mode: $e');
      }

      // If external mode failed, try with platform default
      if (!launched) {
        try {
          final Uri uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );
          }
        } catch (e) {
          print('Failed to launch in platform default mode: $e');
        }
      }

      // If platform default failed, try with in-app webview
      if (!launched) {
        try {
          final Uri uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
                enableDomStorage: true,
              ),
            );
          }
        } catch (e) {
          print('Failed to launch in in-app webview mode: $e');
        }
      }

      if (!launched) {
        throw Exception('Could not launch checkout URL after multiple attempts');
      }

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

  void startTokenRefreshTimer() {
    // Cancel any existing timer first
    stopTokenRefreshTimer();

    // Create a new timer that fetches token usage every 5 seconds
    _tokenRefreshTimer = Timer.periodic(Duration(seconds: _tokenRefreshInterval), (timer) {
      fetchTokenUsage();
    });

    print('Token refresh timer started. Will refresh every $_tokenRefreshInterval seconds');
  }

  // Add this method to stop the token refresh timer
  void stopTokenRefreshTimer() {
    if (_tokenRefreshTimer != null) {
      _tokenRefreshTimer!.cancel();
      _tokenRefreshTimer = null;
      print('Token refresh timer stopped');
    }
  }

  @override
  void dispose() {
    stopTokenRefreshTimer();
    super.dispose();
  }
}
