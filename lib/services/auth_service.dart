// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  // ใช้ .env แทน hardcode
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // User data
  bool _isExpert = false;
  String? _userId;
  String? _userEmail;
  String? _token;
  DateTime? _tokenExpirationDate;

  // Getters
  bool get isExpert => _isExpert;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get token => _token;
  bool get isAuthenticated => _token != null && !isTokenExpired();

  // Check if token is expired
  bool isTokenExpired() {
    if (_token == null || _tokenExpirationDate == null) {
      return true;
    }
    return _tokenExpirationDate!.isBefore(DateTime.now());
  }

  // Get auth headers for API requests
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  // Initialize - load from storage if available
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _userEmail = prefs.getString('userEmail');
      _isExpert = prefs.getBool('isExpert') ?? false;

      // Get token expiration date from SharedPreferences
      final expiryMillis = prefs.getInt('tokenExpiration');
      if (expiryMillis != null) {
        _tokenExpirationDate = DateTime.fromMillisecondsSinceEpoch(
          expiryMillis,
        );
      }

      // If token exists, validate it
      if (_token != null) {
        // Check if token is expired
        if (isTokenExpired()) {
          print('Token is expired, clearing auth data');
          await signOut();
          return false;
        }

        // Optional: Validate token with backend
        return await validateToken();
      }

      return false;
    } catch (e) {
      print('Error initializing auth service: $e');
      return false;
    }
  }

  // Validate token with the backend
  Future<bool> validateToken() async {
    if (_token == null) return false;

    try {
      // Make a lightweight request to verify the token
      final response = await http.get(
        Uri.parse('$apiBaseUrl/users/me'),
        headers: getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        print('Token is valid');
        return true;
      } else {
        print('Token validation failed: ${response.statusCode}');
        if (response.statusCode == 401 || response.statusCode == 403) {
          // Token is invalid, clear auth data
          await signOut();
        }
        return false;
      }
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  // Parse JWT token and extract data
  void _parseJwtToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final payloadMap = jsonDecode(decoded);

        _userId = payloadMap['id'];
        _isExpert = payloadMap['role'] == 'expert';

        // Extract expiration date if available
        if (payloadMap.containsKey('exp')) {
          final expSeconds = payloadMap['exp'] as int;
          _tokenExpirationDate = DateTime.fromMillisecondsSinceEpoch(
            expSeconds * 1000,
          );
        } else {
          // If no expiration in token, set default (e.g., 24 hours from now)
          _tokenExpirationDate = DateTime.now().add(Duration(hours: 24));
        }
      }
    } catch (e) {
      print('Error parsing JWT token: $e');
    }
  }

  // ใน auth_service.dart เพิ่ม method นี้
  Future<http.Response> authenticatedPatch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.patch(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response;
  }

  // Sign in and set role
  Future<bool> signIn(String email, String password) async {
    try {
      print('🔑 LOGIN ATTEMPT:');
      print('📧 Email: $email');
      print('🔐 Password: $password');
      print('🌐 API URL: $apiBaseUrl/users/login');

      final requestBody = {'email': email, 'password': password};
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📱 Response status: ${response.statusCode}');
      print('📱 Response headers: ${response.headers}');
      print('📱 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _userEmail = email;

        print('✅ Login successful!');
        print('🎫 Token received: ${_token?.substring(0, 20)}...');

        // Parse JWT token
        _parseJwtToken(_token!);

        // Save to storage
        await _saveAuthData();

        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Login failed with status: ${response.statusCode}');
        print('❌ Error details: ${error['error'] ?? 'Unknown error'}');
        print('❌ Full error response: $error');
        return false;
      }
    } catch (e) {
      print('💥 Sign in exception: $e');
      print('💥 Exception type: ${e.runtimeType}');
      return false;
    }
  }

  // Save auth data to persistent storage
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('userId', _userId ?? '');
    await prefs.setString('userEmail', _userEmail ?? '');
    await prefs.setBool('isExpert', _isExpert);

    // Save token expiration date
    if (_tokenExpirationDate != null) {
      await prefs.setInt(
        'tokenExpiration',
        _tokenExpirationDate!.millisecondsSinceEpoch,
      );
    }
  }

  // Sign up
  Future<bool> signUp(
    String email,
    String password,
    String confirmPassword,
    String username,
    String firstname,
    String lastname,
    String phone,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'username': username,
          'firstname': firstname,
          'lastname': lastname,
          'phone': phone,
          'role': role.toLowerCase(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Auto sign in after successful registration
        return await signIn(email, password);
      } else {
        final error = jsonDecode(response.body);
        print('Signup error: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Sign up error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isExpert = false;
    _userId = null;
    _userEmail = null;
    _token = null;
    _tokenExpirationDate = null;

    // Clear storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('isExpert');
    await prefs.remove('tokenExpiration');
  }

  // HTTP GET with auth and automatic handling of auth errors
  Future<dynamic> authenticatedGet(
    String endpoint, {
    BuildContext? context,
  }) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    if (isTokenExpired()) {
      // Handle expired token
      if (context != null) {
        // Navigate to login screen if context is provided
        await signOut();
        Navigator.of(context).pushReplacementNamed('/login');
      }
      throw Exception('Token expired');
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: getAuthHeaders(),
      );

      print('GET $endpoint status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Success
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Auth error
        print('Authentication error: ${response.statusCode}');

        // Sign out and redirect to login if context is provided
        await signOut();
        if (context != null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }

        throw Exception('Authentication failed');
      } else {
        print('Response body: ${response.body}');
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in authenticatedGet: $e');
      rethrow;
    }
  }

  // HTTP POST with auth and automatic handling of auth errors
  Future<dynamic> authenticatedPost(
    String endpoint,
    Map<String, dynamic> data, {
    BuildContext? context,
  }) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    if (isTokenExpired()) {
      // Handle expired token
      if (context != null) {
        // Navigate to login screen if context is provided
        await signOut();
        Navigator.of(context).pushReplacementNamed('/login');
      }
      throw Exception('Token expired');
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: getAuthHeaders(),
        body: jsonEncode(data),
      );

      print('POST $endpoint status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Auth error
        print('Authentication error: ${response.statusCode}');

        // Sign out and redirect to login if context is provided
        await signOut();
        if (context != null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }

        throw Exception('Authentication failed');
      } else {
        print('Response body: ${response.body}');
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in authenticatedPost: $e');
      rethrow;
    }
  }
}
