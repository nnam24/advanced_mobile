enum SubscriptionType { free, pro }

class UserSubscription {
  final SubscriptionType type;
  final int tokens;
  final DateTime? expiryDate;

  const UserSubscription({
    this.type = SubscriptionType.free,
    this.tokens = 10,
    this.expiryDate,
  });

  bool get isProActive =>
      type == SubscriptionType.pro &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  int get availableTokens =>
      isProActive ? -1 : tokens; // -1 represents unlimited

  String get displayTokens => isProActive ? 'Unlimited' : tokens.toString();

  UserSubscription copyWith({
    SubscriptionType? type,
    int? tokens,
    DateTime? expiryDate,
  }) {
    return UserSubscription(
      type: type ?? this.type,
      tokens: tokens ?? this.tokens,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'tokens': tokens,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      type:
          json['type'] == 'SubscriptionType.pro'
              ? SubscriptionType.pro
              : SubscriptionType.free,
      tokens: json['tokens'] ?? 10,
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.parse(json['expiryDate'])
              : null,
    );
  }
}
