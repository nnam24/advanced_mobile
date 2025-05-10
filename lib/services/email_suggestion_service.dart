import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class EmailSuggestionService extends ChangeNotifier {
  final String _baseUrl = 'https://dev-api.jarvis.cx/api/v1';
  final String _guidHeader = 'baf60c1e-c61b-496d-ad92-f5aeeadf4def';

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _error = '';
  int _remainingUsage = 50; // Default value

  bool get isLoading => _isLoading;
  String get error => _error;
  int get remainingUsage => _remainingUsage;

  // Helper method to get the current token
  Future<String?> _getToken() async {
    return await _authService.getAccessToken();
  }

  // Helper method to refresh the token
  Future<String?> _refreshToken() async {
    try {
      await _authService.refreshToken();
      return await _authService.getAccessToken();
    } catch (e) {
      _error = 'Failed to refresh token: $e';
      return null;
    }
  }

  // Helper method to make authenticated API calls with token refresh
  Future<http.Response?> _makeAuthenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    int retryCount = 0,
  }) async {
    if (retryCount > 1) {
      _error = 'Too many retry attempts';
      return null;
    }

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'No authentication token available';
        return null;
      }

      final Uri uri = Uri.parse('$_baseUrl/$endpoint');
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'x-jarvis-guid': _guidHeader,
      };

      http.Response response;

      if (method == 'GET') {
        response = await http.get(uri, headers: headers)
            .timeout(const Duration(seconds: 30), onTimeout: () {
          throw Exception('Request timed out');
        });
      } else if (method == 'POST') {
        response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          throw Exception('Request timed out');
        });
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      // Handle 401 Unauthorized error
      if (response.statusCode == 401) {
        debugPrint('Token expired, refreshing...');
        final newToken = await _refreshToken();
        if (newToken != null) {
          return _makeAuthenticatedRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            retryCount: retryCount + 1,
          );
        } else {
          _error = 'Failed to refresh authentication token';
          return null;
        }
      }

      return response;
    } catch (e) {
      _error = e.toString();
      debugPrint('API request error: $_error');
      return null;
    }
  }

  // Tạo phản hồi email đầy đủ
  Future<Map<String, dynamic>> generateEmailResponse({
    required String emailContent,
    required String mainIdea,
    required String action,
    required String subject,
    required String sender,
    required String receiver,
    String language = 'vietnamese',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _makeAuthenticatedRequest(
        endpoint: 'ai-email',
        method: 'POST',
        body: {
          'mainIdea': mainIdea,
          'action': action,
          'email': emailContent,
          'metadata': {
            'context': [],
            'subject': subject,
            'sender': sender,
            'receiver': receiver,
            'style': {
              'length': 'long',
              'formality': 'neutral',
              'tone': 'friendly'
            },
            'language': language
          }
        },
      );

      if (response == null) {
        throw Exception('Failed to make API request');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _remainingUsage = data['remainingUsage'] ?? _remainingUsage;
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        throw Exception('Failed to generate email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Generate email error: $_error');
      return {'error': _error};
    }
  }

  // Lấy ý tưởng trả lời cho email
  Future<List<String>> getReplyIdeas({
    required String emailContent,
    required String subject,
    required String sender,
    required String receiver,
    String language = 'vietnamese',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _makeAuthenticatedRequest(
        endpoint: 'ai-email/reply-ideas',
        method: 'POST',
        body: {
          'action': 'Suggest 3 ideas for this email',
          'email': emailContent,
          'metadata': {
            'context': [],
            'subject': subject,
            'sender': sender,
            'receiver': receiver,
            'language': language
          }
        },
      );

      if (response == null) {
        throw Exception('Failed to make API request');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return List<String>.from(data['ideas'] ?? []);
      } else {
        throw Exception('Failed to get reply ideas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Get reply ideas error: $_error');
      return [];
    }
  }

  // Helper method để tạo email với ý định cụ thể
  Future<Map<String, dynamic>> generateEmailWithIntent({
    required String emailContent,
    required String subject,
    required String sender,
    required String receiver,
    required String intent,
    String language = 'vietnamese',
  }) async {
    String mainIdea = '';
    String action = '';

    switch (intent) {
      case 'thanks':
        mainIdea = 'Xin cảm ơn thông tin đã cung cấp.';
        action = 'Hãy viết email cảm ơn';
        break;
      case 'sorry':
        mainIdea = 'Xin lỗi về sự bất tiện đã gây ra.';
        action = 'Hãy viết email xin lỗi';
        break;
      case 'yes':
        mainIdea = 'Đồng ý với đề xuất/yêu cầu.';
        action = 'Hãy viết email đồng ý';
        break;
      case 'no':
        mainIdea = 'Từ chối đề xuất/yêu cầu một cách lịch sự.';
        action = 'Hãy viết email từ chối lịch sự';
        break;
      case 'followup':
        mainIdea = 'Theo dõi về vấn đề đã đề cập trước đó.';
        action = 'Hãy viết email theo dõi';
        break;
      case 'moreinfo':
        mainIdea = 'Yêu cầu thêm thông tin về vấn đề.';
        action = 'Hãy viết email yêu cầu thêm thông tin';
        break;
      default:
        mainIdea = 'Phản hồi email.';
        action = 'Hãy viết email phản hồi một các đầy đủ';
    }

    return generateEmailResponse(
      emailContent: emailContent,
      mainIdea: mainIdea,
      action: action,
      subject: subject,
      sender: sender,
      receiver: receiver,
      language: language,
    );
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
