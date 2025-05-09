import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
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

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$authApiBaseUrl/password/sign-in'),
        headers: baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Sign in failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      await _storeAuthTokens(data);
      return data;
    } catch (error) {
      print('Sign in error: $error');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp(String email, String password, {String? verificationCallbackUrl}) async {
    try {
      final response = await http.post(
        Uri.parse('$authApiBaseUrl/password/sign-up'),
        headers: baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'verification_callback_url': verificationCallbackUrl ?? defaultCallbackUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Sign up failed: ${response.statusCode}');
      }

      return jsonDecode(response.body);
    } catch (error) {
      print('Sign up error: $error');
      rethrow;
    }
  }

  // Refresh the authentication token
  Future<bool> refreshToken() async {
    try {
      final tokens = await getStoredAuthTokens();
      final refreshToken = tokens['refreshToken'];

      if (refreshToken == null) {
        print('No refresh token available');
        return false;
      }

      final headers = Map<String, String>.from(baseHeaders);
      headers['X-Stack-Refresh-Token'] = refreshToken;

      final response = await http.post(
        Uri.parse('$authApiBaseUrl/sessions/current/refresh'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print('Token refresh failed: ${response.statusCode}');
        return false;
      }

      final data = jsonDecode(response.body);
      await _storeAuthTokens(data);
      return true;
    } catch (error) {
      print('Refresh token error: $error');
      return false;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final tokens = await getStoredAuthTokens();
    return tokens['accessToken'];
  }

  // Logout the current user
  Future<void> logout() async {
    try {
      final tokens = await getStoredAuthTokens();
      final refreshToken = tokens['refreshToken'];
      final accessToken = tokens['accessToken'];

      if (refreshToken == null || accessToken == null) {
        print('No tokens available for logout');
        return;
      }

      final headers = Map<String, String>.from(baseHeaders);
      headers['X-Stack-Refresh-Token'] = refreshToken;
      headers['Authorization'] = 'Bearer $accessToken';

      final response = await http.delete(
        Uri.parse('$authApiBaseUrl/sessions/current'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print('Logout failed: ${response.statusCode}');
      }

      await _clearAuthTokens();
    } catch (error) {
      print('Logout error: $error');
      // Still clear tokens locally even if API call fails
      await _clearAuthTokens();
    }
  }

  // Store auth tokens in SharedPreferences
  Future<void> _storeAuthTokens(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data.containsKey('access_token')) {
      await prefs.setString('access_token', data['access_token']);
    }

    if (data.containsKey('refresh_token')) {
      await prefs.setString('refresh_token', data['refresh_token']);
    }
  }

  // Get stored auth tokens
  Future<Map<String, String?>> getStoredAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'accessToken': prefs.getString('access_token'),
      'refreshToken': prefs.getString('refresh_token'),
    };
  }

  // Clear auth tokens on logout
  Future<void> _clearAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final tokens = await getStoredAuthTokens();
    return tokens['accessToken'] != null && tokens['refreshToken'] != null;
  }
}
