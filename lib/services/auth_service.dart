import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'token_refresh_timer.dart';

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
  TokenRefreshTimer? _refreshTimer;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the refresh timer (initializes lazily)
  TokenRefreshTimer get refreshTimer {
    _refreshTimer ??= TokenRefreshTimer();
    // Set the AuthService instance to avoid circular dependency
    _refreshTimer!.setAuthService(this);
    return _refreshTimer!;
  }

  /// Ensure the service is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to initialize AuthService: $e');
        }
        // Don't rethrow here, let the calling method handle it
      }
    }
  }

  // Storage keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Initialize the AuthService with ApiService dependency
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('AuthService already initialized, skipping...');
      }
      return;
    }

    try {
      // Only initialize ApiService if it's not already initialized
      if (_apiService == null) {
        _apiService = ApiService();
        // Don't call initialize() on ApiService here since it's already initialized in main.dart
      }
      _isInitialized = true;
      if (kDebugMode) {
        print('AuthService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AuthService: $e');
      }
      // Reset initialization state on error
      _isInitialized = false;
      rethrow;
    }
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
    if (enableSwaggerLogging && kDebugMode) {
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
    await _ensureInitialized();

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
        if (kDebugMode) {
          print(
            '✅ Login successful for: ${response['data']['user']['username'] ?? response['data']['user']['email'] ?? 'User'}',
          );
        }

        // Store tokens and user data
        await _storeAuthData(response['data']);

        // Start the automatic refresh timer
        await refreshTimer.start();

        return {
          'success': true,
          'data': response['data'],
          'message': response['message'] ?? 'Login successful',
        };
      } else {
        // Extract error message from response
        // Priority: Errors array > Message field > default message
        String errorMsg = 'Login failed';
        
        if (response['errors'] != null && response['errors'] is List) {
          final errors = response['errors'] as List;
          if (errors.isNotEmpty) {
            errorMsg = errors.first.toString();
          }
        } else if (response['message'] != null) {
          errorMsg = response['message'];
        }
        
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } on UnauthorizedException {
      return {'success': false, 'error': 'Invalid username or password'};
    } on ApiException catch (e) {
      // Handle specific API errors with better messages
      if (kDebugMode) {
        print('🔍 ApiException caught - Status: ${e.statusCode}, Message: ${e.message}');
      }

      // Check if we have a list of errors from the backend
      if (e.data is List && (e.data as List).isNotEmpty) {
        final errors = e.data as List;
        // Format as bullet points
        final formattedError = errors.map((err) => '$err').join('\n');
        return {'success': false, 'error': formattedError};
      }

      
      if (e.statusCode == 401) {
        return {'success': false, 'error': 'Invalid username or password'};
      } else if (e.statusCode == 404) {
        return {'success': false, 'error': 'Account not found'};
      } else if (e.statusCode == 403) {
        return {'success': false, 'error': 'Account is inactive or suspended'};
      } else if (e.statusCode == 500) {
        // For 500 errors, use the message extracted from Errors array
        if (kDebugMode) {
          print('🔍 500 Error - Returning message: ${e.message}');
        }
        return {'success': false, 'error': e.message};
      } else if (e.message.toLowerCase().contains('inactive')) {
        return {'success': false, 'error': 'Account is inactive'};
      } else if (e.message.toLowerCase().contains('suspended')) {
        return {'success': false, 'error': 'Account has been suspended'};
      } else if (e.message.toLowerCase().contains('not found')) {
        return {'success': false, 'error': 'Account not found'};
      }
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {
        'success': false,
        'error': 'Unable to connect. Please check your network.',
      };
    }
  }

  /// Logout method with automatic token cleanup
  ///
  /// Returns a Map with success status
  Future<Map<String, dynamic>> logout() async {
    await _ensureInitialized();

    try {
      final logoutEndpoint = '/auth/logout';
      final fullUrl = '${_apiService?.baseUrl ?? baseUrl}$logoutEndpoint';

      if (kDebugMode) {
        print('POST Request: $fullUrl');
      }
      _logApiCall('POST', fullUrl);

      // Stop the refresh timer
      refreshTimer.stop();

      // Clear stored authentication data
      await _clearAuthData();

      _logApiCall(
        'POST',
        '${_apiService?.baseUrl ?? baseUrl}$logoutEndpoint',
        response: '{"success": true}',
        statusCode: 200,
      );

      if (kDebugMode) {
        print('✅ User logged out successfully');
      }
      return {'success': true, 'message': 'Logout successful'};
    } catch (e) {
      // Even if logout fails, clear local data
      refreshTimer.stop();
      await _clearAuthData();
      if (kDebugMode) {
        print('⚠️ Logout error (local data cleared): $e');
      }
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
    await _ensureInitialized();

    try {
      // Don't refresh if user is not logged in
      if (!(await isLoggedIn())) {
        if (kDebugMode) {
          print('User not logged in, skipping token refresh');
        }
        return false;
      }

      // Don't refresh if token has already expired
      if (await isTokenExpired()) {
        if (kDebugMode) {
          print('Token has already expired, skipping refresh');
        }
        await _clearAuthData();
        return false;
      }

      final refreshToken = await _getStoredRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          print('No refresh token available');
        }
        return false;
      }

      final refreshEndpoint =
          dotenv.env['AUTH_REFRESH_ENDPOINT'] ?? '/auth/refresh-token-mobile';

      final requestBody = {'refreshToken': refreshToken};

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
        if (kDebugMode) {
          print('Token refreshed successfully');
        }

        return true;
      } else {
        if (kDebugMode) {
          print('Token refresh failed: ${response['message']}');
        }
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh failed: $e');
      }
      // Clear auth data if refresh fails
      await _clearAuthData();
      return false;
    }
  }

  /// Mobile refresh token method using the backend-suggested endpoint
  ///
  /// [refreshToken] - The refresh token to use for authentication
  /// Returns a Map with success status and new token data
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final refreshEndpoint = '/auth/refresh-token-mobile';

      final requestBody = {'refreshToken': refreshToken};

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
        if (kDebugMode) {
          print('✅ Mobile refresh token successful');
        }

        return {
          'success': true,
          'data': response['data'],
          'message': response['message'] ?? 'Token refreshed successfully',
        };
      } else {
        if (kDebugMode) {
          print('❌ Mobile refresh token failed: ${response['message']}');
        }
        await _clearAuthData();
        return {
          'success': false,
          'error': response['message'] ?? 'Token refresh failed',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mobile refresh token error: $e');
      }
      await _clearAuthData();
      return {'success': false, 'error': 'Network error during token refresh'};
    }
  }

  /// Refresh user profile data from API
  Future<Map<String, dynamic>> refreshUserProfile() async {
    await _ensureInitialized();

    try {
      final response = await _apiService!.get('/auth/me');

      if (response['success'] == true && response['data'] != null) {
        // Store updated user data
        await _storeAuthData(response['data']);
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to fetch profile: $e',
      };
    }
  }

  /// Change password method
  ///
  /// [userId] - The user's ID
  /// [currentPassword] - The user's current password
  /// [newPassword] - The new password
  /// [confirmPassword] - Confirmation of the new password
  /// Returns a Map with success status and message
  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _ensureInitialized();

    try {
      final changePasswordEndpoint = '/auth/change-password/$userId';

      final requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      _logApiCall(
        'PATCH',
        '${_apiService?.baseUrl ?? baseUrl}$changePasswordEndpoint',
        body: json.encode(requestBody),
      );

      final response = await _apiService!.patch(
        changePasswordEndpoint,
        body: requestBody,
      );

      _logApiCall(
        'PATCH',
        '${_apiService?.baseUrl ?? baseUrl}$changePasswordEndpoint',
        response: json.encode(response),
        statusCode: 200,
      );

      if (response['success'] == true) {
        if (kDebugMode) {
          print('✅ Password changed successfully');
        }
        return {
          'success': true,
          'message': response['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Failed to change password',
        };
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('🔍 ApiException during password change: ${e.message}');
      }
      return {'success': false, 'error': e.message};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Password change error: $e');
      }
      return {
        'success': false,
        'error': 'Unable to change password. Please try again.',
      };
    }
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
        if (kDebugMode) {
          print(
            '✅ Access token stored successfully: ${token.substring(0, 20)}...',
          );
        }
      }

      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
        if (kDebugMode) {
          print(
            '✅ Refresh token stored successfully: ${refreshToken.substring(0, 20)}...',
          );
        }
      }

      // Store user data from login response
      await prefs.setString(_userDataKey, json.encode(userData));
      await prefs.setBool(_isLoggedInKey, true);
      if (kDebugMode) {
        print('User data stored successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing auth data: $e');
      }
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
      if (kDebugMode) {
        print('Auth data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing auth data: $e');
      }
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
      if (kDebugMode) {
        print('Error getting stored user data: $e');
      }
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
      if (kDebugMode) {
        print('Error checking login status: $e');
      }
      return false;
    }
  }

  /// Get stored auth token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored token: $e');
      }
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> _getStoredRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored refresh token: $e');
      }
      return null;
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
          final padding = (4 - payload.length % 4) % 4;
          final paddedPayload = payload + '=' * padding;
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
        if (kDebugMode) {
          print('Error parsing token expiration: $e');
        }
        // If we can't parse the token, assume it might be expired
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking token expiration: $e');
      }
      return true; // Assume expired if we can't check
    }
  }

  /// Check if the current token has already expired
  /// Returns true if token has expired
  Future<bool> isTokenExpired() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        return true; // No token means it's expired
      }

      // For JWT tokens, we can decode and check expiration
      try {
        // Basic JWT payload extraction (this is simplified)
        final parts = token.split('.');
        if (parts.length == 3) {
          // Decode the payload (base64url)
          final payload = parts[1];
          // Add padding if needed
          final padding = (4 - payload.length % 4) % 4;
          final paddedPayload = payload + '=' * padding;
          final decoded = utf8.decode(base64Url.decode(paddedPayload));
          final payloadMap = json.decode(decoded) as Map<String, dynamic>;

          final exp = payloadMap['exp'] as int?;
          if (exp != null) {
            final expirationTime = DateTime.fromMillisecondsSinceEpoch(
              exp * 1000,
            );
            final now = DateTime.now();

            // Token is expired if current time is past expiration
            return now.isAfter(expirationTime);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing token expiration: $e');
        }
        // If we can't parse the token, assume it's expired
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if token is expired: $e');
      }
      return true; // Assume expired if we can't check
    }
  }

  /// Enhanced refresh method that checks for token expiration
  Future<bool> refreshIfNeeded() async {
    try {
      // Don't refresh if user is not logged in
      if (!(await isLoggedIn())) {
        if (kDebugMode) {
          print('User not logged in, skipping token refresh');
        }
        return false;
      }

      // Don't refresh if token has already expired
      if (await isTokenExpired()) {
        if (kDebugMode) {
          print('Token has already expired, skipping refresh');
        }
        await _clearAuthData();
        return false;
      }

      return true; // Token is still valid
    } catch (e) {
      if (kDebugMode) {
        print('Error in refreshIfNeeded: $e');
      }
      return false;
    }
  }

  // ==================== TIMER MANAGEMENT METHODS ====================

  /// Start the automatic refresh token timer
  Future<void> startRefreshTimer() async {
    await refreshTimer.start();
  }

  /// Stop the automatic refresh token timer
  void stopRefreshTimer() {
    refreshTimer.stop();
  }

  /// Restart the automatic refresh token timer
  Future<void> restartRefreshTimer() async {
    await refreshTimer.restart();
  }

  /// Check if the refresh timer is running
  bool isRefreshTimerRunning() {
    return refreshTimer.isRunning;
  }

  /// Get the time until next automatic refresh
  Duration? getTimeUntilNextRefresh() {
    return refreshTimer.getTimeUntilNextRefresh();
  }

  /// Dispose of the refresh timer (call this when the app is being disposed)
  void disposeRefreshTimer() {
    refreshTimer.dispose();
  }

  /// Reset the service (useful for testing or error recovery)
  void reset() {
    _isInitialized = false;
    _apiService = null;
    refreshTimer.stop();
  }
}
