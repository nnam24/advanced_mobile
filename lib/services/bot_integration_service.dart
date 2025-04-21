import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bot_integration_response.dart';

class BotIntegrationService extends ChangeNotifier {
  bool _isLoading = false;
  String _error = '';

  // Base URL for the API
  static const String baseUrl = 'https://knowledge-api.dev.jarvis.cx';

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;

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
          final redirectUrl = jsonData['redirect'];
          print('Redirect URL: $redirectUrl');

          _error = '';
          _isLoading = false;
          notifyListeners();

          return BotIntegrationResponse(
            success: true,
            redirectUrl: redirectUrl,
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

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
