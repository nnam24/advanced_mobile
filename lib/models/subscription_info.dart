class SubscriptionInfo {
  final String name;
  final int dailyTokens;
  final int monthlyTokens;
  final int annuallyTokens;
  final double price;
  final String billingPeriod;
  final DateTime startAt;
  final DateTime endAt;
  final bool trial;

  SubscriptionInfo({
    required this.name,
    required this.dailyTokens,
    required this.monthlyTokens,
    required this.annuallyTokens,
    required this.price,
    required this.billingPeriod,
    required this.startAt,
    required this.endAt,
    required this.trial,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      name: json['name'] ?? 'basic',
      dailyTokens: json['dailyTokens'] ?? 0,
      monthlyTokens: json['monthlyTokens'] ?? 0,
      annuallyTokens: json['annuallyTokens'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      billingPeriod: json['billingPeriod'] ?? 'monthly',
      startAt: json['startAt'] != null ? DateTime.parse(json['startAt']) : DateTime.now(),
      endAt: json['endAt'] != null ? DateTime.parse(json['endAt']) : DateTime.now().add(const Duration(days: 30)),
      trial: json['trial'] ?? false,
    );
  }

  // Helper method to get remaining trial days
  int get remainingTrialDays {
    if (!trial) return 0;
    final now = DateTime.now();
    return endAt.difference(now).inDays;
  }

  // Helper method to format billing period
  String get formattedBillingPeriod {
    switch (billingPeriod) {
      case 'monthly':
        return 'Monthly';
      case 'annually':
        return 'Annually';
      default:
        return 'Free';
    }
  }
}
