import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bot_integration_response.dart';

class BotIntegrationService extends ChangeNotifier {
  bool _isLoading = false;
  String _error = '';

  // Platform-specific redirect URLs
  String? _telegramRedirectUrl;
  String? _slackRedirectUrl;
  String? _messengerRedirectUrl;

  // Base URL for the API
  static const String baseUrl = 'https://knowledge-api.dev.jarvis.cx';

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  String? get telegramRedirectUrl => _telegramRedirectUrl;
  String? get slackRedirectUrl => _slackRedirectUrl;
  String? get messengerRedirectUrl => _messengerRedirectUrl;

  // Get headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final guid = prefs.getString('jarvis_guid') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'x-jarvis-guid': guid,
    };
  }

  // TELEGRAM METHODS

  // Verify Telegram Bot Configuration
  Future<BotIntegrationResponse> verifyTelegramBot(String botToken) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri =
          Uri.parse('$baseUrl/kb-core/v1/bot-integration/telegram/validation');
      final headers = await _getHeaders();

      // Prepare request body
      final requestBody = {
        'botToken': botToken,
      };

      print(
          'Verifying Telegram bot with token: ${botToken.substring(0, 5)}...');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Telegram bot verified successfully');
        _error = '';
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(success: true);
      } else {
        _error = 'Failed to verify Telegram bot: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(
          success: false,
          message: 'Failed to verify Telegram bot: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = 'Exception verifying Telegram bot: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return BotIntegrationResponse(
        success: false,
        message: 'Exception: $e',
      );
    }
  }

  // Publish AI Bot to Telegram
  Future<BotIntegrationResponse> publishToTelegram(
      String assistantId, String botToken) async {
    try {
      _isLoading = true;
      _telegramRedirectUrl = null;
      notifyListeners();

      final uri = Uri.parse(
          '$baseUrl/kb-core/v1/bot-integration/telegram/publish/$assistantId');
      final headers = await _getHeaders();

      // Prepare request body
      final requestBody = {
        'botToken': botToken,
      };

      print('Publishing AI bot to Telegram: $assistantId');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('AI bot published to Telegram successfully');
        print('Response body: ${response.body}');

        // Parse the response to get the redirect URL
        try {
          final jsonData = json.decode(response.body);
          _telegramRedirectUrl = jsonData['redirect'];
          print('Telegram redirect URL: $_telegramRedirectUrl');

          _error = '';
          _isLoading = false;
          notifyListeners();

          return BotIntegrationResponse(
            success: true,
            redirectUrl: _telegramRedirectUrl,
          );
        } catch (e) {
          print('Error parsing response: $e');
          _error = '';
          _isLoading = false;
          notifyListeners();
          return BotIntegrationResponse(success: true);
        }
      } else {
        _error = 'Failed to publish to Telegram: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(
          success: false,
          message: 'Failed to publish to Telegram: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = 'Exception publishing to Telegram: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return BotIntegrationResponse(
        success: false,
        message: 'Exception: $e',
      );
    }
  }

  // SLACK METHODS

  // Verify Slack Bot Configuration
  Future<BotIntegrationResponse> verifySlackBot({
    required String botToken,
    required String clientId,
    required String clientSecret,
    required String signingSecret,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri =
          Uri.parse('$baseUrl/kb-core/v1/bot-integration/slack/validation');
      final headers = await _getHeaders();

      // Prepare request body
      final requestBody = {
        'botToken': botToken,
        'clientId': clientId,
        'clientSecret': clientSecret,
        'signingSecret': signingSecret,
      };

      print('Verifying Slack bot');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Slack bot verified successfully');
        _error = '';
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(success: true);
      } else {
        _error = 'Failed to verify Slack bot: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(
          success: false,
          message: 'Failed to verify Slack bot: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = 'Exception verifying Slack bot: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return BotIntegrationResponse(
        success: false,
        message: 'Exception: $e',
      );
    }
  }

  // Publish AI Bot to Slack
  Future<BotIntegrationResponse> publishToSlack({
    required String assistantId,
    required String botToken,
    required String clientId,
    required String clientSecret,
    required String signingSecret,
  }) async {
    try {
      _isLoading = true;
      _slackRedirectUrl = null;
      notifyListeners();

      final uri = Uri.parse(
          '$baseUrl/kb-core/v1/bot-integration/slack/publish/$assistantId');
      final headers = await _getHeaders();

      // Prepare request body
      final requestBody = {
        'botToken': botToken,
        'clientId': clientId,
        'clientSecret': clientSecret,
        'signingSecret': signingSecret,
      };

      print('Publishing AI bot to Slack: $assistantId');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('AI bot published to Slack successfully');
        print('Response body: ${response.body}');

        // Parse the response to get the redirect URL
        try {
          final jsonData = json.decode(response.body);
          _slackRedirectUrl = jsonData['redirect'];
          print('Slack redirect URL: $_slackRedirectUrl');

          _error = '';
          _isLoading = false;
          notifyListeners();

          return BotIntegrationResponse(
            success: true,
            redirectUrl: _slackRedirectUrl,
          );
        } catch (e) {
          print('Error parsing response: $e');
          _error = '';
          _isLoading = false;
          notifyListeners();
          return BotIntegrationResponse(success: true);
        }
      } else {
        _error = 'Failed to publish to Slack: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(
          success: false,
          message: 'Failed to publish to Slack: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = 'Exception publishing to Slack: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return BotIntegrationResponse(
        success: false,
        message: 'Exception: $e',
      );
    }
  }

  // MESSENGER METHODS

  // Verify Messenger Bot Configuration
  Future<BotIntegrationResponse> verifyMessengerBot({
    required String botToken,
    required String pageId,
    required String appSecret,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri =
          Uri.parse('$baseUrl/kb-core/v1/bot-integration/messenger/validation');
      final headers = await _getHeaders();

      // Prepare request body
      final requestBody = {
        'botToken': botToken,
        'pageId': pageId,
        'appSecret': appSecret,
      };

      print('Verifying Messenger bot');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Messenger bot verified successfully');
        _error = '';
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(success: true);
      } else {
        _error = 'Failed to verify Messenger bot: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(
          success: false,
          message: 'Failed to verify Messenger bot: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = 'Exception verifying Messenger bot: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return BotIntegrationResponse(
        success: false,
        message: 'Exception: $e',
      );
    }
  }

  // Publish AI Bot to Messenger
  Future<BotIntegrationResponse> publishToMessenger({
    required String assistantId,
    required String botToken,
    required String pageId,
    required String appSecret,
  }) async {
    try {
      _isLoading = true;
      _messengerRedirectUrl = null;
      notifyListeners();

      final uri = Uri.parse(
          '$baseUrl/kb-core/v1/bot-integration/messenger/publish/$assistantId');
      final headers = await _getHeaders();

      // Prepare request body
      final requestBody = {
        'botToken': botToken,
        'pageId': pageId,
        'appSecret': appSecret,
      };

      print('Publishing AI bot to Messenger: $assistantId');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('AI bot published to Messenger successfully');
        print('Response body: ${response.body}');

        // Parse the response to get the redirect URL
        try {
          final jsonData = json.decode(response.body);
          _messengerRedirectUrl = jsonData['redirect'];
          print('Messenger redirect URL: $_messengerRedirectUrl');

          _error = '';
          _isLoading = false;
          notifyListeners();

          return BotIntegrationResponse(
            success: true,
            redirectUrl: _messengerRedirectUrl,
          );
        } catch (e) {
          print('Error parsing response: $e');
          _error = '';
          _isLoading = false;
          notifyListeners();
          return BotIntegrationResponse(success: true);
        }
      } else {
        _error = 'Failed to publish to Messenger: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return BotIntegrationResponse(
          success: false,
          message: 'Failed to publish to Messenger: ${response.statusCode}',
        );
      }
    } catch (e) {
      _error = 'Exception publishing to Messenger: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return BotIntegrationResponse(
        success: false,
        message: 'Exception: $e',
      );
    }
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
