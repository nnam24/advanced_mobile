class BotIntegrationResponse {
  final bool success;
  final String? redirectUrl;
  final String? error;
  final String? message;

  BotIntegrationResponse({
    required this.success,
    this.redirectUrl,
    this.error,
    this.message,
  });

  factory BotIntegrationResponse.fromJson(Map<String, dynamic> json) {
    return BotIntegrationResponse(
      success: true,
      redirectUrl: json['redirect'],
      error: null,
      message: null,
    );
  }

  factory BotIntegrationResponse.error(String errorMessage) {
    return BotIntegrationResponse(
      success: false,
      redirectUrl: null,
      error: errorMessage,
      message: null,
    );
  }
}
