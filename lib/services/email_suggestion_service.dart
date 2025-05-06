import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailSuggestionService extends ChangeNotifier {
  final String _baseUrl = 'https://api.jarvis.cx/api/v1';
  final String _authToken = 'eyJhbGciOiJFUzI1NiIsImtpZCI6InFsWUdfYXNMRTI0VSJ9.eyJzdWIiOiIyNTk4Yjk3YS02MWU0LTQ0Y2UtYWJjNC0xMjQ5N2RhZjA2Y2MiLCJicmFuY2hJZCI6Im1haW4iLCJpc3MiOiJodHRwczovL2FjY2Vzcy10b2tlbi5qd3Qtc2lnbmF0dXJlLnN0YWNrLWF1dGguY29tIiwiaWF0IjoxNzQzNzg3MzY5LCJhdWQiOiI0NWExZTJmZC03N2VlLTQ4NzItOWZiNy05ODdiOGMxMTk2MzMiLCJleHAiOjE3NTE1NjMzNjl9.oqYM5aMMiuF-Cg9RpcbmvAEw9a3SRpckKr2NyxQ58aMM-yBRzR9y3ogaeMJHzeXtVNtacuFsMd04roDlGGtwKQ';
  final String _guidHeader = 'baf60c1e-c61b-496d-ad92-f5aeeadf4def';
  
  bool _isLoading = false;
  String _error = '';
  int _remainingUsage = 50; // Default value
  
  bool get isLoading => _isLoading;
  String get error => _error;
  int get remainingUsage => _remainingUsage;
  
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
      
      final response = await http.post(
        Uri.parse('$_baseUrl/ai-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'x-jarvis-guid': _guidHeader,
        },
        body: jsonEncode({
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
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _remainingUsage = data['remainingUsage'] ?? _remainingUsage;
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        throw Exception('Failed to generate email: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
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
      
      final response = await http.post(
        Uri.parse('$_baseUrl/ai-email/reply-ideas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'x-jarvis-guid': _guidHeader,
        },
        body: jsonEncode({
          'action': 'Suggest 3 ideas for this email',
          'email': emailContent,
          'metadata': {
            'context': [],
            'subject': subject,
            'sender': sender,
            'receiver': receiver,
            'language': language
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return List<String>.from(data['ideas'] ?? []);
      } else {
        throw Exception('Failed to get reply ideas: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
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
