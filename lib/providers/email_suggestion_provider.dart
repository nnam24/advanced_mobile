import 'package:flutter/material.dart';
import '../services/email_suggestion_service.dart';

class EmailSuggestionProvider extends ChangeNotifier {
  final EmailSuggestionService _emailService = EmailSuggestionService();
  
  String _emailContent = '';
  String _subject = '';
  String _sender = '';
  String _receiver = '';
  String _generatedResponse = '';
  List<String> _replyIdeas = [];
  List<String> _improvedActions = [];
  bool _isGenerating = false;
  String _error = '';
  
  String get emailContent => _emailContent;
  String get subject => _subject;
  String get sender => _sender;
  String get receiver => _receiver;
  String get generatedResponse => _generatedResponse;
  List<String> get replyIdeas => _replyIdeas;
  List<String> get improvedActions => _improvedActions;
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
  
  void setSender(String sender) {
    _sender = sender;
    notifyListeners();
  }
  
  void setReceiver(String receiver) {
    _receiver = receiver;
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
        sender: _sender,
        receiver: _receiver,
        intent: intent,
        language: language,
      );
      
      _generatedResponse = response['email'] ?? '';
      if (response.containsKey('improvedActions')) {
        _improvedActions = List<String>.from(response['improvedActions'] ?? []);
      }
      
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
        sender: _sender,
        receiver: _receiver,
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
