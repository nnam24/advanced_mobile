class TokenUsage {
  final int availableTokens;
  final int totalTokens;
  final bool unlimited;
  final DateTime date;

  TokenUsage({
    required this.availableTokens,
    required this.totalTokens,
    required this.unlimited,
    required this.date,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      availableTokens: json['availableTokens'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
      unlimited: json['unlimited'] ?? false,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  // Default empty usage
  factory TokenUsage.empty() {
    return TokenUsage(
      availableTokens: 0,
      totalTokens: 0,
      unlimited: false,
      date: DateTime.now(),
    );
  }
}
