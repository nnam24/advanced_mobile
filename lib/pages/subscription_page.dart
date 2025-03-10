import 'package:flutter/material.dart';
import 'package:final_application/components/token_display.dart';
import 'package:final_application/models/user_subscription.dart';
import 'package:final_application/services/subscription_service.dart';
import 'package:final_application/services/iap_service.dart';
import 'package:final_application/services/ad_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final IAPService _iapService = IAPService.instance;
  final AdService _adService = AdService.instance;
  bool _isLoading = false;
  UserSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
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

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _subscription ?? const UserSubscription();

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            subscription.isProActive
                                ? Colors.amber.shade100
                                : Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        subscription.isProActive ? Icons.star : Icons.upgrade,
                        size: 60,
                        color:
                            subscription.isProActive
                                ? Colors.amber.shade700
                                : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subscription.isProActive
                          ? 'You have Pro Access!'
                          : 'Upgrade to Pro',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TokenDisplay(),
                    const SizedBox(height: 16),
                    if (subscription.isProActive &&
                        subscription.expiryDate != null)
                      Text(
                        'Your subscription is valid until ${_formatDate(subscription.expiryDate!)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Pro Features
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pro Features:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.all_inclusive,
                        title: 'Unlimited Tokens',
                        description:
                            'Never run out of tokens for AI processing',
                      ),
                      _buildFeatureItem(
                        icon: Icons.block,
                        title: 'Ad-Free Experience',
                        description: 'No advertisements while using the app',
                      ),
                      _buildFeatureItem(
                        icon: Icons.bolt,
                        title: 'Priority Processing',
                        description:
                            'Faster response times for your AI requests',
                      ),
                      _buildFeatureItem(
                        icon: Icons.security,
                        title: 'Advanced Security',
                        description:
                            'Enhanced security features for your account',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subscription Options
              if (!subscription.isProActive) ...[
                const Text(
                  'Select a Plan:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      _buildSubscriptionOption(
                        title: 'Monthly Pro',
                        price: '\$9.99/month',
                        description: 'Unlimited access on a monthly basis',
                        onTap:
                            () => _purchaseSubscription(
                              _findProduct('pro_monthly_subscription'),
                            ),
                        isPopular: false,
                      ),
                      const SizedBox(height: 12),
                      _buildSubscriptionOption(
                        title: 'Yearly Pro',
                        price: '\$79.99/year',
                        description: 'Save 33% with an annual subscription',
                        onTap:
                            () => _purchaseSubscription(
                              _findProduct('pro_yearly_subscription'),
                            ),
                        isPopular: true,
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Token Packages
                const Text(
                  'Add More Tokens:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildTokenPackage(
                          tokens: 10,
                          price: '\$1.99',
                          onTap:
                              () => _purchaseTokens(
                                _findProduct('tokens_10_pack'),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTokenPackage(
                          tokens: 50,
                          price: '\$8.99',
                          onTap:
                              () => _purchaseTokens(
                                _findProduct('tokens_50_pack'),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTokenPackage(
                          tokens: 100,
                          price: '\$14.99',
                          onTap:
                              () => _purchaseTokens(
                                _findProduct('tokens_100_pack'),
                              ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Free Tokens
                ElevatedButton.icon(
                  onPressed: _watchAdForTokens,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Watch Ad for 5 Free Tokens'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                ),
              ] else ...[
                // Restore Purchases
                ElevatedButton.icon(
                  onPressed: _restorePurchases,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Purchases'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel Subscription
                OutlinedButton.icon(
                  onPressed: _cancelSubscription,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Subscription'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildAdBanner(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption({
    required String title,
    required String price,
    required String description,
    required VoidCallback onTap,
    required bool isPopular,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPopular ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPopular ? Colors.blue : Colors.grey.shade300,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenPackage({
    required int tokens,
    required String price,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            const Icon(Icons.token, color: Colors.blue, size: 24),
            const SizedBox(height: 8),
            Text(
              '$tokens Tokens',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildAdBanner() {
    final adService = AdService.instance;
    final subscription = _subscription ?? const UserSubscription();

    if (subscription.isProActive ||
        !adService.adsEnabled ||
        !adService.isBannerAdLoaded ||
        adService.bannerAd == null) {
      return null;
    }

    return SizedBox(height: 50, child: AdWidget(ad: adService.bannerAd!));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  ProductDetails? _findProduct(String id) {
    try {
      return _iapService.products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _purchaseSubscription(ProductDetails? product) async {
    if (product == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product not available')));
      return;
    }

    await _iapService.buyProduct(product);
  }

  Future<void> _purchaseTokens(ProductDetails? product) async {
    if (product == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product not available')));
      return;
    }

    await _iapService.buyProduct(product);
  }

  Future<void> _watchAdForTokens() async {
    await _adService.showRewardedAd(
      onRewarded: (reward) {
        final int amount = reward.amount.toInt();
        _subscriptionService.addTokens(amount);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You earned $amount tokens!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  Future<void> _restorePurchases() async {
    await _iapService.restorePurchases();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Purchases restored')));
  }

  Future<void> _cancelSubscription() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Subscription'),
            content: const Text(
              'Are you sure you want to cancel your subscription? '
              'You will lose access to Pro features when your current subscription period ends.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No, Keep It'),
              ),
              TextButton(
                onPressed: () {
                  // In a real app, you would need to cancel the subscription with the store
                  // Here we just downgrade in our local system
                  _subscriptionService.downgradeToFree();
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your subscription has been cancelled. '
                        'You will have access until the end of your billing period.',
                      ),
                    ),
                  );
                },
                child: const Text('Yes, Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }
}
