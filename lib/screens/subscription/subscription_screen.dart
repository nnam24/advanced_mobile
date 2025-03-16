import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/animated_background.dart';
import '../../models/subscription_plan.dart';

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
    final currentPlan = authProvider.currentUser?.plan ?? 'free';
    
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
                    // Current Plan Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPlanColor(currentPlan).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getPlanName(currentPlan),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getPlanColor(currentPlan),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getPlanDescription(currentPlan),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Token Balance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.token,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${authProvider.currentUser?.tokenBalance ?? 0} tokens',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Plan Selection
                    Text(
                      'Choose a Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Plan Cards
                    for (int i = 0; i < plans.length; i++)
                      _buildPlanCard(context, plans[i], i),
                    
                    const SizedBox(height: 24),
                    
                    // Upgrade Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: subscriptionProvider.isLoading
                            ? null
                            : () => _upgradePlan(context, plans[_selectedPlanIndex]),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: subscriptionProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Upgrade to ${plans[_selectedPlanIndex].name}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Terms and Conditions
                    Text(
                      'By upgrading, you agree to our Terms of Service and Privacy Policy. Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan, int index) {
    final isSelected = _selectedPlanIndex == index;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentPlan = authProvider.currentUser?.plan ?? 'free';
    final isCurrentPlan = plan.id == currentPlan;
    
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPlanColor(plan.id).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getPlanIcon(plan.id),
                        color: _getPlanColor(plan.id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '\$${plan.price.toStringAsFixed(2)} / ${plan.billingCycle}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Radio<int>(
                    value: index,
                    groupValue: _selectedPlanIndex,
                    onChanged: (value) {
                      setState(() {
                        _selectedPlanIndex = value!;
                      });
                      HapticFeedback.lightImpact();
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _upgradePlan(BuildContext context, SubscriptionPlan plan) async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if this is the current plan
    if (plan.id == authProvider.currentUser?.plan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already subscribed to this plan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to ${plan.name}?'),
        content: Text(
          'You will be charged \$${plan.price.toStringAsFixed(2)} for the ${plan.billingCycle} plan. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await subscriptionProvider.subscribeToPlan(plan.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully upgraded to ${plan.name}!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upgrade: ${subscriptionProvider.error}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getPlanColor(String planId) {
    switch (planId) {
      case 'free':
        return Colors.grey;
      case 'premium':
        return Colors.blue;
      case 'enterprise':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPlanIcon(String planId) {
    switch (planId) {
      case 'free':
        return Icons.star_border;
      case 'premium':
        return Icons.star_half;
      case 'enterprise':
        return Icons.star;
      default:
        return Icons.star_border;
    }
  }

  String _getPlanName(String planId) {
    switch (planId) {
      case 'free':
        return 'Free';
      case 'premium':
        return 'Premium';
      case 'enterprise':
        return 'Enterprise';
      default:
        return 'Unknown';
    }
  }

  String _getPlanDescription(String planId) {
    switch (planId) {
      case 'free':
        return 'Basic access';
      case 'premium':
        return 'Enhanced features';
      case 'enterprise':
        return 'Full access';
      default:
        return '';
    }
  }
}

