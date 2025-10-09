import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Custom exception classes for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Main API service class that handles all HTTP requests
/// with automatic token management and error handling
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final String _baseUrl;
  late final AuthService _authService;
  late final http.Client _client;

  /// Initialize the API service with base URL and dependencies
  Future<void> initialize() async {
    _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5278/api/v1';
    _authService = AuthService();
    _client = http.Client();

    print('ApiService initialized with base URL: $_baseUrl');
  }

  /// Get the base URL for API requests
  String get baseUrl => _baseUrl;

  /// Get the full URL by combining base URL with endpoint
  String _getFullUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return '$_baseUrl/$cleanEndpoint';
  }

  /// Get headers with authorization token
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add Bearer token for mobile app authentication
    final token = await _authService.getStoredToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle HTTP response and throw appropriate exceptions
  void _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        // Success - no exception needed
        break;
      case 400:
        // Parse error response according to backend study guide format
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final message = errorData['message'] ?? 'Bad request';
          final errors = errorData['errors'] as List<dynamic>?;
          throw ApiException(message, statusCode: 400, data: errors);
        } catch (e) {
          throw const ApiException('Bad request', statusCode: 400);
        }
      case 401:
        throw const UnauthorizedException('Authentication required');
      case 403:
        throw const ApiException('Access forbidden', statusCode: 403);
      case 404:
        throw const ApiException('Resource not found', statusCode: 404);
      case 409:
        // Parse conflict response according to backend study guide format
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final message = errorData['message'] ?? 'Conflict';
          throw ApiException(message, statusCode: 409);
        } catch (e) {
          throw const ApiException('Conflict', statusCode: 409);
        }
      case 422:
        throw const ApiException('Validation error', statusCode: 422);
      case 500:
        throw const ApiException('Internal server error', statusCode: 500);
      default:
        throw ApiException(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }

  /// Perform GET request
  ///
  /// [endpoint] - API endpoint (e.g., '/users' or 'users')
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map<String, dynamic>
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      String url = _getFullUrl(endpoint);

      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        final newUri = uri.replace(queryParameters: queryParams);
        url = newUri.toString();
      }

      print('GET Request: $url');

      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      final response = await _client.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService.refresh();
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client.get(
            Uri.parse(url),
            headers: newHeaders,
          );
          _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      _handleResponse(response);
      return json.decode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on FormatException {
      throw const ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException ||
          e is NetworkException ||
          e is UnauthorizedException) {
        rethrow;
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Perform POST request
  ///
  /// [endpoint] - API endpoint (e.g., '/users' or 'users')
  /// [body] - Request body as Map<String, dynamic>
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map<String, dynamic>
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = _getFullUrl(endpoint);
      print('POST Request: $url');

      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      final response = await _client.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService.refresh();
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client.post(
            Uri.parse(url),
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
          _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      _handleResponse(response);
      return json.decode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on FormatException {
      throw const ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException ||
          e is NetworkException ||
          e is UnauthorizedException) {
        rethrow;
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Perform DELETE request
  ///
  /// [endpoint] - API endpoint (e.g., '/users/123' or 'users/123')
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map<String, dynamic>
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = _getFullUrl(endpoint);
      print('DELETE Request: $url');

      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      final response = await _client.delete(
        Uri.parse(url),
        headers: requestHeaders,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService.refresh();
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client.delete(
            Uri.parse(url),
            headers: newHeaders,
          );
          _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      _handleResponse(response);
      return json.decode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on FormatException {
      throw const ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException ||
          e is NetworkException ||
          e is UnauthorizedException) {
        rethrow;
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Perform PUT request
  ///
  /// [endpoint] - API endpoint (e.g., '/users/123' or 'users/123')
  /// [body] - Request body as Map<String, dynamic>
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map<String, dynamic>
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = _getFullUrl(endpoint);
      print('PUT Request: $url');

      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      final response = await _client.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService.refresh();
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client.put(
            Uri.parse(url),
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
          _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      _handleResponse(response);
      return json.decode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on FormatException {
      throw const ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException ||
          e is NetworkException ||
          e is UnauthorizedException) {
        rethrow;
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _client.close();
  }
}
