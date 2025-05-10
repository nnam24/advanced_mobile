class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String billingCycle;
  final List<String> features;
  final bool isPopular;
  final String? trialPeriod;
  final String? savePercentage;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.features,
    this.isPopular = false,
    this.trialPeriod,
    this.savePercentage,
  });
}
