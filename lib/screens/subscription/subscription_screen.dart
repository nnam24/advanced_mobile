import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/animated_background.dart';
import '../../models/subscription_plan.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Fetch current subscription info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.fetchCurrentSubscription();

      // Set default selected plan to match current plan (basic by default)
      final currentPlan = subscriptionProvider.currentSubscription?.name ?? 'basic';
      final index = subscriptionProvider.plans.indexWhere((plan) => plan.id == currentPlan);
      if (index != -1) {
        setState(() {
          _selectedPlanIndex = index;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final plans = subscriptionProvider.plans;
    final currentSubscription = subscriptionProvider.currentSubscription;
    final tokenUsage = subscriptionProvider.tokenUsage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Your Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Token Balance Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.token,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (subscriptionProvider.isLoadingTokens)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else if (tokenUsage != null)
                            Text(
                              tokenUsage.unlimited
                                  ? 'Unlimited tokens'
                                  : '${NumberFormat('#,###').format(tokenUsage.availableTokens)} / ${NumberFormat('#,###').format(tokenUsage.totalTokens)} tokens',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            )
                          else
                            Text(
                              'No token data available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Current Plan Info
                    if (subscriptionProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (currentSubscription != null)
                      _buildCurrentPlanCard(context, currentSubscription),

                    const SizedBox(height: 24),

                    // Plan Selection
                    Text(
                      'Choose a Plan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Plan Cards - Vertical layout
                    ...plans.map((plan) => _buildPlanCard(context, plan, plans.indexOf(plan))).toList(),

                    const SizedBox(height: 24),

                    // Terms and Conditions
                    Text(
                      'By upgrading, you agree to our Terms of Service and Privacy Policy. Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, dynamic currentSubscription) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final remainingDays = currentSubscription.remainingTrialDays;

    // Get the display name based on the plan name
    String displayPlanName = _getPlanName(currentSubscription.name);

    // Get the billing period display text
    String billingPeriodText = currentSubscription.formattedBillingPeriod;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPlanColor(currentSubscription.name).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Plan name and billing period
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getPlanColor(currentSubscription.name).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayPlanName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getPlanColor(currentSubscription.name),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                billingPeriodText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Price
          if (currentSubscription.price > 0)
            Text(
              'Price: \$${currentSubscription.price.toStringAsFixed(2)}/${currentSubscription.billingPeriod == 'monthly' ? 'month' : 'year'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

          const SizedBox(height: 8),

          // Trial info
          if (currentSubscription.trial)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trial period: $remainingDays days remaining',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Subscription period
          Text(
            'Start date: ${dateFormat.format(currentSubscription.startAt)}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'End date: ${dateFormat.format(currentSubscription.endAt)}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan, int index) {
    final isSelected = _selectedPlanIndex == index;
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final currentSubscription = subscriptionProvider.currentSubscription;
    final isCurrentPlan = currentSubscription != null && plan.id == currentSubscription.name;

    return GestureDetector(
      onTap: () {
        if (!isCurrentPlan) {
          setState(() {
            _selectedPlanIndex = index;
          });
          HapticFeedback.lightImpact();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Hot Pick badge
            if (plan.id == 'pro')
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thumb_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HOT PICK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Plan content
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Plan header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPlanIcon(plan.id),
                        color: _getPlanColor(plan.id),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getPlanName(plan.id),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getPlanColor(plan.id),
                        ),
                      ),
                    ],
                  ),
                ),

                // Price section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      if (plan.id == 'basic')
                        Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      else
                        Column(
                          children: [
                            Text(
                              '1-month Free Trial',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Then',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.id == 'starter'
                                  ? '\$9.99/month'
                                  : '\$79.99/year',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),

                      // Save percentage
                      if (plan.id == 'pro')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SAVE 33% ON ANNUAL PLAN!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Subscribe button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCurrentPlan || subscriptionProvider.isLoading
                          ? null
                          : () => _upgradePlan(context, plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: plan.id == 'pro' ? Colors.amber : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        isCurrentPlan
                            ? 'Current Plan'
                            : subscriptionProvider.isLoading
                            ? 'Processing...'
                            : 'Subscribe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const Divider(height: 32),

                // Features section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Basic features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Basic features
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                          context,
                          'AI Chat Model${plan.id == 'basic' ? '' : 's'}',
                          plan.id == 'basic'
                              ? 'GPT-3.5'
                              : 'GPT-3.5 & GPT-4.0/Turbo & Gemini Pro & Gemini Ultra'
                      ),
                      _buildFeatureItem(context, 'AI Action Injection', ''),
                      _buildFeatureItem(context, 'Select Text for AI Action', ''),
                    ],
                  ),
                ),

                const Divider(height: 32),

                // Queries section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      plan.id == 'basic'
                          ? 'Limited queries per day'
                          : plan.id == 'starter'
                          ? 'More queries per month'
                          : 'More queries per year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Queries feature
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFeatureItem(
                      context,
                      plan.id == 'basic'
                          ? '50 free queries per day'
                          : plan.id == 'starter'
                          ? 'Unlimited queries per month'
                          : 'Unlimited queries per year',
                      ''
                  ),
                ),

                const Divider(height: 32),

                // Advanced features section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Advanced features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Advanced features
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFeatureItem(context, 'AI Reading Assistant', ''),
                      _buildFeatureItem(context, 'Real-time Web Access', ''),
                      _buildFeatureItem(context, 'AI Writing Assistant', ''),
                      _buildFeatureItem(context, 'AI Pro Search', ''),
                      if (plan.id != 'basic') ...[
                        _buildFeatureItem(context, 'Jira Copilot Assistant', ''),
                        _buildFeatureItem(context, 'Github Copilot Assistant', ''),
                      ],
                    ],
                  ),
                ),

                if (plan.id != 'basic') ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Maximize productivity with unlimited* queries.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],

                const Divider(height: 32),

                // Other benefits section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Other benefits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Other benefits
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFeatureItem(
                      context,
                      plan.id == 'basic'
                          ? 'Lower response speed during high-traffic'
                          : 'No request limits during high-traffic',
                      ''
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _upgradePlan(BuildContext context, SubscriptionPlan plan) async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    // Determine the period based on the plan
    String planId;
    String period;

    if (plan.id == 'basic') {
      // For basic plan, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are now on the Basic plan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } else if (plan.id == 'starter') {
      planId = 'starter';
      period = 'monthly';
    } else if (plan.id == 'pro') {
      planId = 'starter'; // Use 'starter' for Pro plan as requested
      period = 'annually';
    } else {
      planId = plan.id;
      period = 'monthly';
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to ${plan.name}?'),
        content: Text(
          'You will be redirected to the payment page to complete your subscription. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await subscriptionProvider.subscribeToPlan(planId, period);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process subscription: ${subscriptionProvider.error}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getPlanColor(String planId) {
    switch (planId) {
      case 'basic':
        return Colors.blue.shade800;
      case 'starter':
        return Colors.blue;
      case 'pro':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getPlanIcon(String planId) {
    switch (planId) {
      case 'basic':
        return Icons.brightness_low;
      case 'starter':
        return Icons.all_inclusive;
      case 'pro':
        return Icons.star;
      default:
        return Icons.star_border;
    }
  }

  String _getPlanName(String planId) {
    switch (planId) {
      case 'basic':
        return 'Basic';
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Pro Annually';
      default:
        return 'Unknown';
    }
  }
}
