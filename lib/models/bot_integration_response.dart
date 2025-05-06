class BotIntegrationResponse {
  final bool success;
  final String? message;
  final String? redirectUrl;

  BotIntegrationResponse({
    required this.success,
    this.message,
    this.redirectUrl,
  });

  factory BotIntegrationResponse.fromJson(Map<String, dynamic> json) {
    return BotIntegrationResponse(
      success: true,
      redirectUrl: json['redirect'],
    );
  }
}
