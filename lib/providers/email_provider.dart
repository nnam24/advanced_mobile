import 'package:flutter/material.dart';
import '../services/email_service.dart';

class EmailProvider extends ChangeNotifier {
  final EmailService _emailService = EmailService();
  
  String _emailContent = '';
  String _subject = '';
  String _recipient = '';
  String _generatedResponse = '';
  List<String> _replyIdeas = [];
  bool _isGenerating = false;
  String _error = '';
  
  String get emailContent => _emailContent;
  String get subject => _subject;
  String get recipient => _recipient;
  String get generatedResponse => _generatedResponse;
  List<String> get replyIdeas => _replyIdeas;
  bool get isGenerating => _isGenerating;
  String get error => _error;
  int get remainingUsage => _emailService.remainingUsage;
  
  void setEmailContent(String content) {
    _emailContent = content;
    notifyListeners();
  }
  
  void setSubject(String subject) {
    _subject = subject;
    notifyListeners();
  }
  
  void setRecipient(String recipient) {
    _recipient = recipient;
    notifyListeners();
  }
  
  void clearGeneratedResponse() {
    _generatedResponse = '';
    notifyListeners();
  }
  
  Future<void> generateEmailWithIntent({
    required String intent,
    String language = 'vietnamese',
  }) async {
    try {
      _isGenerating = true;
      _error = '';
      notifyListeners();
      
      final response = await _emailService.generateEmailWithIntent(
        emailContent: _emailContent,
        subject: _subject,
        sender: 'user@example.com', // Replace with actual user email
        receiver: _recipient,
        intent: intent,
        language: language,
      );
      
      _generatedResponse = response;
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  Future<void> getReplyIdeas({
    String language = 'vietnamese',
  }) async {
    try {
      _isGenerating = true;
      _error = '';
      notifyListeners();
      
      final ideas = await _emailService.getReplyIdeas(
        emailContent: _emailContent,
        subject: _subject,
        sender: 'sender@example.com', // Replace with actual sender
        receiver: 'user@example.com', // Replace with actual user email
        language: language,
      );
      
      _replyIdeas = ideas;
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
