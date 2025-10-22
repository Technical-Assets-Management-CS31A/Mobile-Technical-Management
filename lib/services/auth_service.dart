import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Enhanced AuthService with token management and SharedPreferences integration
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  ApiService? _apiService;
  bool _isInitialized = false;

  // Storage keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Initialize the AuthService with ApiService dependency
  Future<void> initialize() async {
    if (_isInitialized) {
      print('AuthService already initialized, skipping...');
      return;
    }

    _apiService = ApiService();
    // Don't call initialize() on ApiService here since it's already initialized in main.dart
    _isInitialized = true;
    print('AuthService initialized');
  }

  /// Get API base URL from environment variables
  String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5278/api/v1';

  /// Get Swagger base URL
  String get swaggerBaseUrl =>
      dotenv.env['SWAGGER_BASE_URL'] ?? 'http://localhost:5278';

  /// Get Swagger UI URL
  String get swaggerUiUrl =>
      dotenv.env['SWAGGER_UI_URL'] ?? 'http://localhost:5278/swagger-ui.html';

  /// Get API timeout from environment variables
  int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  /// Check if Swagger logging is enabled
  bool get enableSwaggerLogging =>
      dotenv.env['ENABLE_SWAGGER_LOGGING'] == 'true';

  /// Log API request/response if enabled
  void _logApiCall(
    String method,
    String url, {
    String? body,
    String? response,
    int? statusCode,
  }) {
    if (enableSwaggerLogging) {
      print('=== AUTH API CALL ===');
      print('$method $url');
      if (body != null) print('Request Body: $body');
      if (response != null) print('Response: $response');
      if (statusCode != null) print('Status Code: $statusCode');
      print('=====================');
    }
  }

  /// Login method with automatic token storage
  ///
  /// [identifier] - User's username or email (will be sent as identifier)
  /// [password] - User's password
  ///
  /// Returns a Map with success status and user data or error message
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final loginEndpoint =
          dotenv.env['AUTH_LOGIN_ENDPOINT'] ?? '/auth/login-mobile';

      // Backend expects 'identifier' field according to study guide
      final requestBody = {'identifier': identifier, 'password': password};

      _logApiCall(
        'POST',
        '${_apiService?.baseUrl ?? baseUrl}$loginEndpoint',
        body: json.encode(requestBody),
      );

      final response = await _apiService!.post(
        loginEndpoint,
        body: requestBody,
      );

      _logApiCall(
        'POST',
        '${_apiService?.baseUrl ?? baseUrl}$loginEndpoint',
        response: json.encode(response),
        statusCode: 200,
      );

      // Handle response according to backend study guide format
      if (response['success'] == true && response['data'] != null) {
        // Debug: User login successful
        print(
          '✅ Login successful for: ${response['data']['user']['username'] ?? response['data']['user']['email'] ?? 'User'}',
        );

        // Store tokens and user data
        await _storeAuthData(response['data']);
        return {
          'success': true,
          'data': response['data'],
          'message': response['message'] ?? 'Login successful',
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Login failed',
        };
      }
    } on UnauthorizedException {
      return {'success': false, 'error': 'Invalid credentials'};
    } on ApiException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  /// Logout method with automatic token cleanup
  ///
  /// Returns a Map with success status
  Future<Map<String, dynamic>> logout() async {
    try {
      final logoutEndpoint =
          dotenv.env['AUTH_LOGOUT_ENDPOINT'] ?? '/auth/logout';

      _logApiCall('POST', '${_apiService?.baseUrl ?? baseUrl}$logoutEndpoint');

      // Attempt to call logout endpoint (optional - may fail if token is already invalid)
      try {
        await _apiService!.post(logoutEndpoint);
      } catch (e) {
        // Ignore logout endpoint errors - we still want to clear local data
        print('Logout endpoint call failed (this is usually fine): $e');
      }

      // Clear stored authentication data
      await _clearAuthData();

      _logApiCall(
        'POST',
        '${_apiService?.baseUrl ?? baseUrl}$logoutEndpoint',
        response: '{"success": true}',
        statusCode: 200,
      );

      return {'success': true, 'message': 'Logout successful'};
    } catch (e) {
      // Even if logout fails, clear local data
      await _clearAuthData();
      return {
        'success': true,
        'message': 'Logout successful (local data cleared)',
      };
    }
  }

  /// Refresh token method - called automatically by ApiService
  ///
  /// Returns true if refresh was successful, false otherwise
  Future<bool> refresh() async {
    try {
      final refreshToken = await _getStoredRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('No refresh token available');
        return false;
      }

      final refreshEndpoint =
          dotenv.env['AUTH_REFRESH_ENDPOINT'] ?? '/auth/refresh-token';

      final requestBody = {'refresh_token': refreshToken};

      _logApiCall(
        'POST',
        '${_apiService?.baseUrl ?? baseUrl}$refreshEndpoint',
        body: json.encode(requestBody),
      );

      final response = await _apiService!.post(
        refreshEndpoint,
        body: requestBody,
      );

      _logApiCall(
        'POST',
        '${_apiService?.baseUrl ?? baseUrl}$refreshEndpoint',
        response: json.encode(response),
        statusCode: 200,
      );

      // Handle response according to backend study guide format
      if (response['success'] == true && response['data'] != null) {
        // Store new tokens
        await _storeAuthData(response['data']);
        print('Token refreshed successfully');

        // Check if the response indicates the token is almost expired
        if (response['data']['tokenExpiresSoon'] == true ||
            response['data']['expiresSoon'] == true ||
            response['message']?.toString().toLowerCase().contains(
                  'expires soon',
                ) ==
                true) {
          print('Token expires soon, requesting another refresh token...');
          // Request another refresh token proactively
          await _requestProactiveRefresh();
        }

        return true;
      } else {
        print('Token refresh failed: ${response['message']}');
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      print('Token refresh failed: $e');
      // Clear auth data if refresh fails
      await _clearAuthData();
      return false;
    }
  }

  /// Legacy method for backward compatibility
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final success = await refresh();
    return {
      'success': success,
      'data': success ? await getStoredUserData() : null,
    };
  }

  /// Get Swagger API documentation
  Future<Map<String, dynamic>> getSwaggerDocs() async {
    try {
      final response = await _apiService!.get('/v3/api-docs');
      return {'success': true, 'data': response};
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error while fetching documentation',
      };
    }
  }

  /// Test API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await _apiService!.get('/health');
      return {
        'success': true,
        'message': 'API connection successful',
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // ==================== TOKEN MANAGEMENT METHODS ====================

  /// Store authentication data in SharedPreferences
  Future<void> _storeAuthData(Map<String, dynamic> response) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Extract tokens from response for mobile app Bearer token authentication
      final token = response['accessToken'];
      final refreshToken = response['refreshToken'];
      final userData = response['user'] ?? response;

      // Store tokens for Bearer authentication
      if (token != null) {
        await prefs.setString(_tokenKey, token);
        print(
          '✅ Access token stored successfully: ${token.substring(0, 20)}...',
        );
      }

      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
        print(
          '✅ Refresh token stored successfully: ${refreshToken.substring(0, 20)}...',
        );
      }

      // Store user data from login response
      await prefs.setString(_userDataKey, json.encode(userData));
      await prefs.setBool(_isLoggedInKey, true);
      print('User data stored successfully');
    } catch (e) {
      print('Error storing auth data: $e');
    }
  }

  /// Clear all authentication data from SharedPreferences
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.setBool(_isLoggedInKey, false);
      print('Auth data cleared successfully');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return json.decode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting stored user data: $e');
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final token = prefs.getString(_tokenKey);
      // Check if user is logged in and has a valid token
      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Get stored auth token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting stored token: $e');
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> _getStoredRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Error getting stored refresh token: $e');
      return null;
    }
  }

  /// Request a proactive refresh token when current token expires soon
  Future<void> _requestProactiveRefresh() async {
    try {
      print('Requesting proactive refresh token...');
      final success = await refresh();
      if (success) {
        print('Proactive refresh token obtained successfully');
      } else {
        print('Failed to obtain proactive refresh token');
      }
    } catch (e) {
      print('Error during proactive refresh: $e');
    }
  }

  /// Check if the current token is almost expired
  /// Returns true if token expires within the next 5 minutes
  Future<bool> isTokenExpiringSoon() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        return true; // No token means it's "expired"
      }

      // For JWT tokens, we can decode and check expiration
      // This is a simplified check - in production you might want to use a JWT library
      try {
        // Basic JWT payload extraction (this is simplified)
        final parts = token.split('.');
        if (parts.length == 3) {
          // Decode the payload (base64url)
          final payload = parts[1];
          // Add padding if needed
          final paddedPayload = payload + '=' * (4 - payload.length % 4);
          final decoded = utf8.decode(base64Url.decode(paddedPayload));
          final payloadMap = json.decode(decoded) as Map<String, dynamic>;

          final exp = payloadMap['exp'] as int?;
          if (exp != null) {
            final expirationTime = DateTime.fromMillisecondsSinceEpoch(
              exp * 1000,
            );
            final now = DateTime.now();
            final timeUntilExpiry = expirationTime.difference(now);

            // Consider token expiring soon if it expires within 5 minutes
            return timeUntilExpiry.inMinutes <= 5;
          }
        }
      } catch (e) {
        print('Error parsing token expiration: $e');
        // If we can't parse the token, assume it might be expired
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking token expiration: $e');
      return true; // Assume expired if we can't check
    }
  }

  /// Enhanced refresh method that checks for token expiration
  Future<bool> refreshIfNeeded() async {
    try {
      // Check if token is expiring soon
      if (await isTokenExpiringSoon()) {
        print('Token is expiring soon, refreshing...');
        return await refresh();
      }
      return true; // Token is still valid
    } catch (e) {
      print('Error in refreshIfNeeded: $e');
      return false;
    }
  }
}
