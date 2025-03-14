import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String _error = '';
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Constructor with mock user for demo
  AuthProvider() {
    // For demo purposes, we'll initialize with a null user
    _currentUser = null;
    _isAuthenticated = false;
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, accept any valid-looking email/password
      if (email.contains('@') && password.length >= 6) {
        _currentUser = User(
          id: '1',
          name: email.split('@')[0],
          email: email,
          photoUrl: '',
          plan: 'free',
          tokenBalance: 1000,
          createdAt: DateTime.now(),
        );
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> register(String name, String email, String password) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, accept any valid-looking registration
      if (name.isNotEmpty && email.contains('@') && password.length >= 6) {
        _currentUser = User(
          id: '1',
          name: name,
          email: email,
          photoUrl: '',
          plan: 'free',
          tokenBalance: 1000,
          createdAt: DateTime.now(),
        );
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid registration data';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, create a mock Google user
      _currentUser = User(
        id: '2',
        name: 'Google User',
        email: 'google.user@example.com',
        photoUrl: '',
        plan: 'free',
        tokenBalance: 1000,
        createdAt: DateTime.now(),
      );
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with Apple
  Future<bool> loginWithApple() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, create a mock Apple user
      _currentUser = User(
        id: '3',
        name: 'Apple User',
        email: 'apple.user@example.com',
        photoUrl: '',
        plan: 'free',
        tokenBalance: 1000,
        createdAt: DateTime.now(),
      );
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, accept any valid-looking email
      if (email.contains('@')) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = null;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(String name, String email) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: name,
          email: email,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, accept any valid-looking passwords
      if (currentPassword.length >= 6 && newPassword.length >= 6) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}

