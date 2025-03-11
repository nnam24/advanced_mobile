class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String billingCycle;
  final List<String> features;
  final int tokenAllowance;
  final int modelLimit;
  final bool hasAdvancedFeatures;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.features,
    required this.tokenAllowance,
    required this.modelLimit,
    required this.hasAdvancedFeatures,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0.0,
      billingCycle: json['billingCycle'] ?? 'month',
      features: List<String>.from(json['features'] ?? []),
      tokenAllowance: json['tokenAllowance'] ?? 0,
      modelLimit: json['modelLimit'] ?? 1,
      hasAdvancedFeatures: json['hasAdvancedFeatures'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'billingCycle': billingCycle,
      'features': features,
      'tokenAllowance': tokenAllowance,
      'modelLimit': modelLimit,
      'hasAdvancedFeatures': hasAdvancedFeatures,
    };
  }
}

