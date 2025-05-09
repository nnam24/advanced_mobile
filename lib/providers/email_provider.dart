import 'package:flutter/material.dart';
import '../models/email_model.dart';
import '../models/user.dart';
import '../services/email_service.dart';
import '../services/auth_service.dart';

class EmailProvider extends ChangeNotifier {
  final User? _currentUser;
  final AuthService _authService;
  late final EmailService _emailService;

  List<EmailModel> _emails = [];
  EmailModel? _selectedEmail;
  String _generatedResponse = '';
  List<String> _replyIdeas = [];
  List<String> _improvedActions = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String _error = '';
  int _remainingUsage = 50; // Default value

  // Constructor nhận thông tin người dùng hiện tại và AuthService
  EmailProvider({User? currentUser, AuthService? authService})
      : _currentUser = currentUser,
        _authService = authService ?? AuthService() {
    _emailService = EmailService(
      currentUser: _currentUser,
      authService: _authService,
    );
  }

  List<EmailModel> get emails => _emails;
  EmailModel? get selectedEmail => _selectedEmail;
  String get generatedResponse => _generatedResponse;
  List<String> get replyIdeas => _replyIdeas;
  List<String> get improvedActions => _improvedActions;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String get error => _error;
  int get remainingUsage => _remainingUsage;

  // Lấy danh sách email
  Future<void> fetchEmails() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final emails = await _emailService.getEmails();
      _emails = emails;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chọn email
  void selectEmail(EmailModel email) {
    _selectedEmail = email;
    _generatedResponse = '';
    _replyIdeas = [];
    _improvedActions = [];
    notifyListeners();
  }

  // Tạo email mới
  Future<void> createEmail(EmailModel email) async {
    try {
      _isLoading = true;
      notifyListeners();

      final savedEmail = await _emailService.saveEmail(email);

      // Cập nhật danh sách email
      await fetchEmails();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật email
  Future<void> updateEmail(EmailModel email) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedEmail = await _emailService.saveEmail(email);

      // Cập nhật danh sách email
      await fetchEmails();

      // Cập nhật email đang chọn nếu cần
      if (_selectedEmail != null && _selectedEmail!.id == updatedEmail.id) {
        _selectedEmail = updatedEmail;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa email
  Future<void> deleteEmail(String emailId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _emailService.deleteEmail(emailId);

      if (success) {
        // Cập nhật danh sách email
        await fetchEmails();

        // Xóa email đang chọn nếu cần
        if (_selectedEmail != null && _selectedEmail!.id == emailId) {
          _selectedEmail = null;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa tất cả email
  Future<void> deleteAllEmails() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _emailService.deleteAllEmails();

      if (success) {
        _emails = [];
        _selectedEmail = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lưu email được tạo
  Future<void> saveGeneratedEmail() async {
    if (_selectedEmail == null || _generatedResponse.isEmpty) {
      _error = 'Không có email để lưu';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Tạo email mới từ email được tạo
      final newEmail = EmailModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: 'Re: ${_selectedEmail!.subject}',
        content: _generatedResponse,
        sender: _selectedEmail!.receiver, // Đảo ngược sender và receiver
        receiver: _selectedEmail!.sender,
        timestamp: DateTime.now(),
      );

      await _emailService.saveEmail(newEmail);

      // Cập nhật danh sách email
      await fetchEmails();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Quy trình 2 bước: Lấy ý tưởng và tạo email
  Future<void> generateEmailWithAction({
    required String action,
    String language = 'vietnamese',
  }) async {
    if (_selectedEmail == null) {
      _error = 'No email selected';
      notifyListeners();
      return;
    }

    try {
      _isGenerating = true;
      _error = '';
      notifyListeners();

      final response = await _emailService.generateEmailWithAction(
        emailContent: _selectedEmail!.content,
        subject: _selectedEmail!.subject,
        sender: _selectedEmail!.receiver, // Đảo ngược sender và receiver khi phản hồi
        receiver: _selectedEmail!.sender,
        action: action,
        language: language,
      );

      _generatedResponse = response['email'] ?? '';
      _replyIdeas = response['ideas'] != null
          ? List<String>.from(response['ideas'])
          : [];
      _improvedActions = response['improvedActions'] != null
          ? List<String>.from(response['improvedActions'])
          : [];
      _remainingUsage = response['remainingUsage'] ?? _remainingUsage;

      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearGeneratedResponse() {
    _generatedResponse = '';
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
