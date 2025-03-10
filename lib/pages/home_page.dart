import 'package:flutter/material.dart';
import 'package:final_application/components/token_display.dart';
import 'package:final_application/models/user_subscription.dart';
import 'package:final_application/services/subscription_service.dart';
import 'package:final_application/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final AdService _adService = AdService.instance;
  UserSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    setState(() {
      _subscription = _subscriptionService.subscription;
    });

    // Listen for subscription changes
    _subscriptionService.subscriptionStream.listen((subscription) {
      if (mounted) {
        setState(() {
          _subscription = subscription;
        });
      }
    });
  }

  Future<void> _simulateAIChat() async {
    // Check if user has tokens
    final canProcessRequest = await _subscriptionService.useToken();

    if (!canProcessRequest) {
      if (mounted) {
        _showNoTokensDialog();
      }
      return;
    }

    // Simulate AI processing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing your request...'),
        duration: Duration(seconds: 1),
      ),
    );

    // After successful processing, show an interstitial ad for free users
    if (!_subscriptionService.subscription.isProActive) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _adService.showInterstitialAd();
    }
  }

  void _showNoTokensDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Out of Tokens'),
            content: const Text(
              'You have run out of tokens. Upgrade to Pro for unlimited tokens '
              'or purchase additional tokens to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/subscription');
                },
                child: const Text('Get Tokens'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _subscription ?? const UserSubscription();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TokenDisplay(),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/subscription');
            },
            icon: const Icon(Icons.diamond_outlined),
            tooltip: 'Upgrade',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'AI Chat Assistant',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                subscription.isProActive
                    ? 'You have unlimited AI chat processing with your Pro account!'
                    : 'You have ${subscription.tokens} tokens remaining for AI chat processing.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _simulateAIChat,
                icon: const Icon(Icons.send),
                label: const Text('Process AI Request'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/subscription');
                },
                icon:
                    subscription.isProActive
                        ? const Icon(Icons.star)
                        : const Icon(Icons.upgrade),
                label: Text(
                  subscription.isProActive
                      ? 'Manage Pro Subscription'
                      : 'Upgrade to Pro',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildAdBanner(),
    );
  }

  Widget? _buildAdBanner() {
    final subscription = _subscription ?? const UserSubscription();

    if (subscription.isProActive ||
        !_adService.adsEnabled ||
        !_adService.isBannerAdLoaded ||
        _adService.bannerAd == null) {
      return null;
    }

    return SizedBox(height: 50, child: AdWidget(ad: _adService.bannerAd!));
  }
}
