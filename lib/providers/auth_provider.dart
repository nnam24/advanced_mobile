import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String _error = '';
  bool _isAuthenticated = false;
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiryTime;
  Timer? _tokenRefreshTimer;

  // Session expiration callback
  Function(String reason)? onSessionExpired;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get refreshToken => _refreshToken;

  // Base URL for auth API
  static const String authApiBaseUrl = 'https://auth-api.dev.jarvis.cx/api/v1/auth';

  // Common headers for all requests
  static Map<String, String> get baseHeaders => {
    'X-Stack-Access-Type': 'client',
    'X-Stack-Project-Id': 'a914f06b-5e46-4966-8693-80e4b9f4f409',
    'X-Stack-Publishable-Client-Key': 'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr',
    'Content-Type': 'application/json',
  };

  // Default verification callback URL
  static const String defaultCallbackUrl = 'https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess';

  // Constructor with auto login attempt
  AuthProvider() {
    _currentUser = null;
    _isAuthenticated = false;
    // Try to auto-login from stored tokens
    tryAutoLogin();
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final response = await http.post(
        Uri.parse('$authApiBaseUrl/password/sign-in'),
        headers: baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _token = responseData['access_token'];
        _refreshToken = responseData['refresh_token'];

        // Set token expiry time (10 minutes from now)
        _tokenExpiryTime = DateTime.now().add(const Duration(minutes: 10));

        // Create user from response data
        final userData = responseData['user'] ?? {};
        _currentUser = User(
          id: userData['id'] ?? '1',
          name: userData['name'] ?? email.split('@')[0],
          email: email,
          photoUrl: userData['photo_url'] ?? '',
          plan: userData['plan'] ?? 'free',
          tokenBalance: userData['token_balance'] ?? 1000,
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'])
              : DateTime.now(),
        );

        _isAuthenticated = true;

        // Store auth data in shared preferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('access_token', _token!);
        prefs.setString('refresh_token', _refreshToken!);
        prefs.setString('token_expiry', _tokenExpiryTime!.toIso8601String());
        prefs.setString('user_email', email);
        prefs.setString('user_name', _currentUser!.name);

        // Start token refresh timer
        _setupTokenRefreshTimer();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = responseData['message'] ?? 'Authentication failed';
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

      final response = await http.post(
        Uri.parse('$authApiBaseUrl/password/sign-up'),
        headers: baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'verification_callback_url': defaultCallbackUrl,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Store the name locally since the API doesn't accept it
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user_name', name);

        // After successful registration, automatically sign in
        return await login(email, password);
      } else {
        _error = responseData['message'] ?? 'Registration failed';
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

  // Login with Google (keeping mock implementation for now)
  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call - would be replaced with actual OAuth implementation
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

      // Set token expiry time (10 minutes from now)
      _tokenExpiryTime = DateTime.now().add(const Duration(minutes: 10));

      // Start token refresh timer
      _setupTokenRefreshTimer();

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

  // Login with Apple (keeping mock implementation for now)
  Future<bool> loginWithApple() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Simulate API call - would be replaced with actual OAuth implementation
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

      // Set token expiry time (10 minutes from now)
      _tokenExpiryTime = DateTime.now().add(const Duration(minutes: 10));

      // Start token refresh timer
      _setupTokenRefreshTimer();

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

  // Reset password (keeping mock implementation for now)
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
  Future<void> logout({String reason = ''}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Cancel token refresh timer
      _cancelTokenRefreshTimer();

      if (_token != null && _refreshToken != null) {
        final headers = Map<String, String>.from(baseHeaders);
        headers['X-Stack-Refresh-Token'] = _refreshToken!;
        headers['Authorization'] = 'Bearer $_token';

        try {
          await http.delete(
            Uri.parse('$authApiBaseUrl/sessions/current'),
            headers: headers,
            body: jsonEncode({}),
          );
        } catch (e) {
          print('API logout error: $e');
          // Continue with local logout even if API call fails
        }
      }

      // Clear data regardless of API response
      _token = null;
      _refreshToken = null;
      _tokenExpiryTime = null;
      _currentUser = null;
      _isAuthenticated = false;

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiry');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_id');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Even if there's an error, we should still clear local data
      _token = null;
      _refreshToken = null;
      _tokenExpiryTime = null;
      _currentUser = null;
      _isAuthenticated = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiry');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_id');

      _error = e.toString();
      _isLoading = false;
      notifyListeners();

      // Rethrow the error for the UI to handle
      throw e;
    }
  }

  // Update user profile (keeping mock implementation for now)
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

        // Update stored user data
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user_email', email);
        prefs.setString('user_name', name);

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

  // Change password (keeping mock implementation for now)
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

  // Refresh the authentication token
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) {
      return false;
    }

    try {
      debugPrint('Refreshing token at ${DateTime.now()}');
      final headers = Map<String, String>.from(baseHeaders);
      headers['X-Stack-Refresh-Token'] = _refreshToken!;

      final response = await http.post(
        Uri.parse('$authApiBaseUrl/sessions/current/refresh'),
        headers: headers,
        body: jsonEncode({}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _token = responseData['access_token'];
        // _refreshToken = responseData['refresh_token'];

        // Update token expiry time (10 minutes from now)
        _tokenExpiryTime = DateTime.now().add(const Duration(minutes: 10));

        // Update stored tokens
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('access_token', _token!);
        // prefs.setString('refresh_token', _refreshToken!);
        prefs.setString('token_expiry', _tokenExpiryTime!.toIso8601String());

        // Reset the timer for the next refresh
        _setupTokenRefreshTimer();

        debugPrint('Token refreshed successfully at ${DateTime.now()}');
        notifyListeners();
        return true;
      } else {
        // Token refresh failed - session might be expired
        debugPrint('Token refresh failed at ${DateTime.now()}');
        await _handleSessionExpiration('Your session has expired. Please login again.');
        return false;
      }
    } catch (e) {
      // Handle network or other errors
      debugPrint('Token refresh error at ${DateTime.now()}: $e');
      await _handleSessionExpiration('Failed to refresh authentication. Please login again.');
      return false;
    }
  }

  // Try to auto-login from stored tokens
  Future<bool> tryAutoLogin() async {
    debugPrint('Attempting auto-login');

    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('access_token') || !prefs.containsKey('refresh_token')) {
      debugPrint('No stored tokens found');
      return false;
    }

    _token = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');

    // Get token expiry time
    final expiryString = prefs.getString('token_expiry');
    if (expiryString != null) {
      _tokenExpiryTime = DateTime.parse(expiryString);
    } else {
      // If no expiry time is stored, set it to 10 minutes from now
      _tokenExpiryTime = DateTime.now().add(const Duration(minutes: 10));
    }

    // Create user from stored data
    final email = prefs.getString('user_email');
    final name = prefs.getString('user_name');

    if (email != null && name != null) {
      _currentUser = User(
        id: '1', // We don't have the real ID stored
        name: name,
        email: email,
        photoUrl: '',
        plan: 'free',
        tokenBalance: 1000,
        createdAt: DateTime.now(),
      );
      _isAuthenticated = true;

      debugPrint('Auto-login successful: $_currentUser');

      // Start token refresh timer regardless of token expiry
      _setupTokenRefreshTimer();

      notifyListeners();
      return true;
    }

    debugPrint('Auto-login failed: user data not found');
    return false;
  }

  // Set up timer to refresh token every 9 minutes
  void _setupTokenRefreshTimer() {
    // Cancel any existing timer
    _cancelTokenRefreshTimer();

    // Set up timer to refresh token every 9 minutes
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 8), (timer) {
      debugPrint('Token refresh timer triggered at ${DateTime.now()}');
      if (_isAuthenticated && _refreshToken != null) {
        refreshAuthToken();
      } else {
        // If not authenticated or no refresh token, cancel the timer
        _cancelTokenRefreshTimer();
      }
    });

    debugPrint('Token refresh timer set up. Next refresh in 9 minutes');
  }

  // Cancel token refresh timer
  void _cancelTokenRefreshTimer() {
    if (_tokenRefreshTimer != null) {
      _tokenRefreshTimer!.cancel();
      _tokenRefreshTimer = null;
      debugPrint('Token refresh timer cancelled');
    }
  }

  // Handle session expiration
  Future<void> _handleSessionExpiration(String reason) async {
    debugPrint('Handling session expiration: $reason');

    // Cancel token refresh timer
    _cancelTokenRefreshTimer();

    // Clear authentication data
    _token = null;
    _refreshToken = null;
    _tokenExpiryTime = null;
    _currentUser = null;
    _isAuthenticated = false;

    // Clear stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');

    // Set error message
    _error = reason;

    // Notify listeners
    notifyListeners();

    // Call session expired callback if set
    if (onSessionExpired != null) {
      onSessionExpired!(reason);
    }
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _cancelTokenRefreshTimer();
    super.dispose();
  }
}
