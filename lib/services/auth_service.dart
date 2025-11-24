// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // ใช้ .env แทน hardcode
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('API_BASE_URL is not set in .env file');
    }
    return url;
  }

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Google Sign In instance
  // Note: serverClientId ต้องตรงกับ GOOGLE_CLIENT_ID ใน backend
  // สำหรับ Flutter, serverClientId ใช้ Client ID ที่สร้างสำหรับ Web application
  GoogleSignIn get _googleSignIn {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      throw Exception('GOOGLE_CLIENT_ID is not set in .env file');
    }
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      // serverClientId: ใช้สำหรับ backend verification
      // ต้องตรงกับ GOOGLE_CLIENT_ID ใน backend .env
      serverClientId: clientId,
    );
  }

  // User data
  bool _isExpert = false;
  String? _userId;
  String? _userEmail;
  String? _token; // Access token
  String? _refreshToken; // Refresh token
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
      _userId = prefs.getString('userId');
      _userEmail = prefs.getString('userEmail');
      _isExpert = prefs.getBool('isExpert') ?? false;

      // Load tokens from secure storage
      _token = await _secureStorage.read(key: 'token');
      _refreshToken = await _secureStorage.read(key: 'refreshToken');

      final expiryString = await _secureStorage.read(key: 'tokenExpiration');
      if (expiryString != null) {
        final expiryMillis = int.tryParse(expiryString);
        if (expiryMillis != null) {
          _tokenExpirationDate = DateTime.fromMillisecondsSinceEpoch(
            expiryMillis,
          );
        }
      }

      // Migrate legacy token data from SharedPreferences if it still exists
      if (_token == null) {
        final legacyToken = prefs.getString('token');
        if (legacyToken != null) {
          _token = legacyToken;
          await _secureStorage.write(key: 'token', value: legacyToken);
          await prefs.remove('token');
        }
      }

      if (_refreshToken == null) {
        final legacyRefreshToken = prefs.getString('refreshToken');
        if (legacyRefreshToken != null) {
          _refreshToken = legacyRefreshToken;
          await _secureStorage.write(
            key: 'refreshToken',
            value: legacyRefreshToken,
          );
          await prefs.remove('refreshToken');
        }
      }

      if (_tokenExpirationDate == null) {
        final legacyExpiry = prefs.getInt('tokenExpiration');
        if (legacyExpiry != null) {
          _tokenExpirationDate = DateTime.fromMillisecondsSinceEpoch(
            legacyExpiry,
          );
          await _secureStorage.write(
            key: 'tokenExpiration',
            value: legacyExpiry.toString(),
          );
          await prefs.remove('tokenExpiration');
        }
      }

      // If token exists, validate it
      if (_token != null) {
        // Check if token is expired
        if (isTokenExpired()) {
          print('Token is expired, trying to refresh...');
          // Try to refresh token if refreshToken exists
          if (_refreshToken != null) {
            final refreshed = await refreshAccessToken();
            if (refreshed) {
              return true;
            }
          }
          print('Token refresh failed, clearing auth data');
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

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        return false;
      }

      // Send idToken to backend
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleAuth.idToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
          _token = data['accessToken'];
          _refreshToken = data['refreshToken'];
          _userEmail = googleUser.email;
          
          // Parse JWT token to get user info
          _parseJwtToken(_token!);
          
          // Save to storage
          await _saveAuthData();
          
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Sign in and set role
  Future<bool> signIn(String email, String password) async {
    try {
      // Mask email for logging (only show part before @)
      final emailMasked = email.contains('@') 
          ? '${email.substring(0, email.indexOf('@'))}@***'
          : '***';
      print('🔑 Login attempt: email=$emailMasked');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password, // Never log password
        }),
      );

      print('📱 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Backend sends 'accessToken' not 'token'
        if (data.containsKey('accessToken')) {
          _token = data['accessToken'];
          _refreshToken = data['refreshToken'];
        } else if (data.containsKey('token')) {
          // Fallback for old API format
          _token = data['token'];
        } else {
          print('❌ Login failed: No token in response');
          return false;
        }
        
        _userEmail = email;

        print('✅ Login successful: userId=$_userId, email=$emailMasked');

        // Parse JWT token
        _parseJwtToken(_token!);

        // Save to storage
        await _saveAuthData();

        return true;
      } else {
        try {
          final error = jsonDecode(response.body);
          final errorMsg = error['error'] ?? 'Unknown error';
          print('❌ Login failed: $errorMsg');
        } catch (e) {
          print('❌ Login failed: Status ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      print('❌ Login error: ${e.toString()}');
      return false;
    }
  }

  // Save auth data to persistent storage
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    if (_token != null) {
      await _secureStorage.write(key: 'token', value: _token);
    }

    if (_refreshToken != null) {
      await _secureStorage.write(
        key: 'refreshToken',
        value: _refreshToken,
      );
    } else {
      await _secureStorage.delete(key: 'refreshToken');
    }

    await prefs.setString('userId', _userId ?? '');
    await prefs.setString('userEmail', _userEmail ?? '');
    await prefs.setBool('isExpert', _isExpert);

    // Save token expiration date
    if (_tokenExpirationDate != null) {
      await _secureStorage.write(
        key: 'tokenExpiration',
        value: _tokenExpirationDate!.millisecondsSinceEpoch.toString(),
      );
    } else {
      await _secureStorage.delete(key: 'tokenExpiration');
    }
  }

  // Sign up
  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String confirmPassword,
    String username,
    String firstname,
    String lastname,
    String phone,
    String role,
    bool privacyConsentAccepted,
  ) async {
    try {
      // Mask email for logging
      final emailMasked = email.contains('@') 
          ? '${email.substring(0, email.indexOf('@'))}@***'
          : '***';
      print('🔐 Signup attempt: email=$emailMasked, username=$username, role=$role');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password, // Never log password
          'confirmPassword': confirmPassword, // Never log password
          'username': username,
          'firstname': firstname,
          'lastname': lastname,
          'phone': phone,
          'role': role.toLowerCase(),
          'privacyConsentAccepted': privacyConsentAccepted,
        }),
      );

      print('📱 Signup response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response and set tokens directly (no need to call signIn)
        final data = jsonDecode(response.body);
        
        if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
          // Set tokens from signup response
          _token = data['accessToken'];
          _refreshToken = data['refreshToken'];
          _userEmail = email;
          
          // Parse JWT token to get user info
          _parseJwtToken(_token!);
          
          // Save to storage
          await _saveAuthData();
          
          print('✅ Signup successful: userId=$_userId, email=$emailMasked');
          return {'success': true, 'message': null};
        } else {
          // Fallback: try to sign in if tokens not in response
          print('⚠️ No tokens in signup response, trying signIn...');
          final signInSuccess = await signIn(email, password);
          return {'success': signInSuccess, 'message': signInSuccess ? null : 'Account created but login failed'};
        }
      } else {
        String errorMessage = 'Failed to create account';
        
        try {
          final errorData = jsonDecode(response.body);
          
          // Handle different error formats
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          } else if (errorData.containsKey('errors') && errorData['errors'] is List) {
            final errors = errorData['errors'] as List;
            if (errors.isNotEmpty) {
              final firstError = errors[0];
              if (firstError is Map && firstError.containsKey('msg')) {
                errorMessage = firstError['msg'].toString();
              } else if (firstError is String) {
                errorMessage = firstError;
              }
            }
          }
        } catch (e) {
          print('❌ Error parsing signup response: $e');
          errorMessage = 'Failed to create account. Please try again.';
        }
        
        print('❌ Signup failed: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('❌ Signup error: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.'
      };
    }
  }

  // Refresh access token using refresh token
  Future<bool> refreshAccessToken({BuildContext? context}) async {
    if (_refreshToken == null) {
      print('❌ Token refresh failed: No refresh token available');
      return false;
    }

    try {
      print('🔄 Refreshing access token...');
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}), // Never log refreshToken
      );

      print('📱 Token refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['accessToken'];
        _refreshToken = data['refreshToken']; // New refresh token (rotation)

        // Parse JWT token to update expiration
        _parseJwtToken(_token!);

        // Save to storage
        await _saveAuthData();

        print('✅ Token refreshed successfully');
        return true;
      } else {
        // Parse error message
        String errorMessage = 'Token refresh failed';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          }
        } catch (e) {
          print('❌ Error parsing refresh error response: $e');
        }
        
        print('❌ Token refresh failed: $errorMessage');
        
        // ถ้า refresh token หมดอายุแล้ว (7 วัน) หรือ invalid -> sign out และ redirect ไป login
        if (errorMessage.toLowerCase().contains('expired') || 
            errorMessage.toLowerCase().contains('invalid') ||
            response.statusCode == 403) {
          print('🔄 Refresh token expired or invalid, signing out...');
          await signOut();
          if (context != null) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
        
        return false;
      }
    } catch (e) {
      print('❌ Token refresh error: ${e.toString()}');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Sign out from Google if signed in
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        print('✅ Signed out from Google');
      }
    } catch (e) {
      print('⚠️ Error signing out from Google: $e');
    }

    final userId = _userId; // Save for logging before clearing
    _isExpert = false;
    _userId = null;
    _userEmail = null;
    _token = null;
    _refreshToken = null;
    _tokenExpirationDate = null;
    
    print('🔓 Logout: userId=$userId');

    // Clear storage
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: 'token');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'tokenExpiration');
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('isExpert');
    await prefs.remove('tokenExpiration');
  }

  // Helper function to parse error message from backend response
  String _parseErrorMessage(String responseBody, int statusCode) {
    String errorMessage = 'Request failed with status: $statusCode';
    try {
      final errorData = jsonDecode(responseBody);
      print('Error response: $errorData');
      
      // Handle validation errors format: { errors: [...] }
      if (errorData.containsKey('errors') && errorData['errors'] is List) {
        final errors = errorData['errors'] as List;
        if (errors.isNotEmpty) {
          final firstError = errors[0];
          if (firstError is Map && firstError.containsKey('msg')) {
            errorMessage = firstError['msg'].toString();
          } else if (firstError is String) {
            errorMessage = firstError;
          }
        }
      } 
      // Handle simple error format: { error: "message" }
      else if (errorData.containsKey('error')) {
        errorMessage = errorData['error'].toString();
      }
    } catch (e) {
      print('Error parsing error response: $e');
    }
    return errorMessage;
  }

  // HTTP GET with auth and automatic handling of auth errors
  Future<dynamic> authenticatedGet(
    String endpoint, {
    BuildContext? context,
  }) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    // ถ้า token expired → ลอง refresh ก่อน (ถ้ามี refresh token)
    if (isTokenExpired()) {
      print('⚠️ Access token expired, attempting to refresh...');
      
      if (_refreshToken != null) {
        final refreshed = await refreshAccessToken(context: context);
        if (refreshed) {
          print('✅ Token refreshed, proceeding with request...');
          // Token refreshed successfully, continue with request
        } else {
          // Refresh failed (refresh token expired or invalid)
          print('❌ Token refresh failed, redirecting to login...');
          await signOut();
          if (context != null) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
          throw Exception('Session expired. Please login again.');
        }
      } else {
        // No refresh token available
        print('❌ No refresh token available, redirecting to login...');
        await signOut();
        if (context != null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        throw Exception('Session expired. Please login again.');
      }
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
        // Auth error - try to refresh token first
        print('Authentication error: ${response.statusCode}, attempting token refresh...');
        
        if (_refreshToken != null) {
          final refreshed = await refreshAccessToken(context: context);
          if (refreshed) {
            // Retry the original request with new token
            print('🔄 Retrying request after token refresh...');
            final retryResponse = await http.get(
              Uri.parse('$apiBaseUrl$endpoint'),
              headers: getAuthHeaders(),
            );
            
            if (retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body);
            }
          }
        }
        
        // Refresh failed or no refresh token - sign out
        print('❌ Token refresh failed, signing out...');
        await signOut();
        if (context != null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }

        throw Exception('Authentication failed');
      } else {
        print('Response body: ${response.body}');
        final errorMessage = _parseErrorMessage(response.body, response.statusCode);
        throw Exception(errorMessage);
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

    // ถ้า token expired → ลอง refresh ก่อน (ถ้ามี refresh token)
    if (isTokenExpired()) {
      print('⚠️ Access token expired, attempting to refresh...');
      
      if (_refreshToken != null) {
        final refreshed = await refreshAccessToken(context: context);
        if (refreshed) {
          print('✅ Token refreshed, proceeding with request...');
          // Token refreshed successfully, continue with request
        } else {
          // Refresh failed (refresh token expired or invalid)
          print('❌ Token refresh failed, redirecting to login...');
          await signOut();
          if (context != null) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
          throw Exception('Session expired. Please login again.');
        }
      } else {
        // No refresh token available
        print('❌ No refresh token available, redirecting to login...');
        await signOut();
        if (context != null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        throw Exception('Session expired. Please login again.');
      }
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
        // Auth error - try to refresh token first
        print('Authentication error: ${response.statusCode}, attempting token refresh...');
        
        if (_refreshToken != null) {
          final refreshed = await refreshAccessToken(context: context);
          if (refreshed) {
            // Retry the original request with new token
            print('🔄 Retrying request after token refresh...');
            final retryResponse = await http.post(
              Uri.parse('$apiBaseUrl$endpoint'),
              headers: getAuthHeaders(),
              body: jsonEncode(data),
            );
            
            if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
              return jsonDecode(retryResponse.body);
            }
          }
        }
        
        // Refresh failed or no refresh token - sign out
        print('❌ Token refresh failed, signing out...');
        await signOut();
        if (context != null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }

        throw Exception('Authentication failed');
      } else {
        print('Response body: ${response.body}');
        final errorMessage = _parseErrorMessage(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in authenticatedPost: $e');
      rethrow;
    }
  }
}
