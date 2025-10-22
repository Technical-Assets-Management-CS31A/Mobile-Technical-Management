import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  String? _baseUrl;
  AuthService? _authService;
  http.Client? _client;
  bool _isInitialized = false;

  /// Initialize the API service with base URL and dependencies
  Future<void> initialize() async {
    if (_isInitialized) {
      print('ApiService already initialized, skipping...');
      return;
    }

    _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5278/api/v1';
    _authService = AuthService();
    _client = http.Client();
    _isInitialized = true;

    print('ApiService initialized with base URL: $_baseUrl');
  }

  /// Get the base URL for API requests
  String get baseUrl => _baseUrl ?? 'http://localhost:5278/api/v1';

  /// Get the full URL by combining base URL with endpoint
  String _getFullUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return '${_baseUrl ?? 'http://localhost:5278/api/v1'}/$cleanEndpoint';
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
    if (_authService != null) {
      // Check if token needs refresh before making request (only if user is logged in)
      final isLoggedIn = await _authService!.isLoggedIn();
      if (isLoggedIn) {
        await _authService!.refreshIfNeeded();
      }

      final token = await _authService!.getStoredToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle HTTP response and throw appropriate exceptions
  Future<void> _handleResponse(http.Response response) async {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        // Success - check for token expiration warnings in response
        await _checkForTokenExpirationWarning(response);
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

  /// Check for token expiration warnings in successful responses
  Future<void> _checkForTokenExpirationWarning(http.Response response) async {
    try {
      if (response.body.isNotEmpty) {
        final responseData = json.decode(response.body);

        // Handle both Map and List response formats
        Map<String, dynamic>? responseMap;
        if (responseData is Map<String, dynamic>) {
          responseMap = responseData;
        } else if (responseData is List) {
          // If response is a list, we can't check for token expiration warnings
          return;
        } else {
          // Unknown response format, skip checking
          return;
        }

        // Check for various token expiration indicators
        final data = responseMap['data'];
        final message = responseMap['message'] as String?;

        // Check if response indicates token expires soon
        if (data is Map<String, dynamic> &&
            (data['tokenExpiresSoon'] == true ||
                data['expiresSoon'] == true ||
                data['tokenExpiryWarning'] == true)) {
          print('⚠️ API response indicates token expires soon');
          // Trigger proactive refresh only if user is logged in
          if (await _authService?.isLoggedIn() == true) {
            _authService?.refreshIfNeeded();
          }
        }

        // Check message for expiration warnings
        if (message != null &&
            (message.toLowerCase().contains('expires soon') ||
                message.toLowerCase().contains('token expiring') ||
                message.toLowerCase().contains('refresh recommended'))) {
          print('⚠️ API message indicates token expiration warning');
          // Trigger proactive refresh only if user is logged in
          if (await _authService?.isLoggedIn() == true) {
            _authService?.refreshIfNeeded();
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors for this check
      print('Error checking for token expiration warning: $e');
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
      final response = await _client!.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService?.refresh() ?? false;
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client!.get(
            Uri.parse(url),
            headers: newHeaders,
          );
          await _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      await _handleResponse(response);
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
      final requestHeaders = await _getHeaders(additionalHeaders: headers);

      final response = await _client!.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService?.refresh() ?? false;
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client!.post(
            Uri.parse(url),
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
          await _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      await _handleResponse(response);
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
      final response = await _client!.delete(
        Uri.parse(url),
        headers: requestHeaders,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService?.refresh() ?? false;
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client!.delete(
            Uri.parse(url),
            headers: newHeaders,
          );
          await _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      await _handleResponse(response);
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
      final response = await _client!.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService?.refresh() ?? false;
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client!.put(
            Uri.parse(url),
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
          await _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      await _handleResponse(response);
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

  /// Perform PATCH request
  ///
  /// [endpoint] - API endpoint (e.g., '/users/123' or 'users/123')
  /// [body] - Request body as Map<String, dynamic>
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map<String, dynamic>
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = _getFullUrl(endpoint);
      print('PATCH Request: $url');

      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      final response = await _client!.patch(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService?.refresh() ?? false;
        if (refreshSuccess) {
          // Retry the request with new token
          final newHeaders = await _getHeaders(additionalHeaders: headers);
          final retryResponse = await _client!.patch(
            Uri.parse(url),
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
          await _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      await _handleResponse(response);

      // Handle 204 No Content responses
      if (response.statusCode == 204) {
        return {'success': true, 'message': 'No content'};
      }

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

  /// Perform POST request with multipart/form-data
  ///
  /// [endpoint] - API endpoint (e.g., '/items' or 'items')
  /// [fields] - Form fields as Map<String, String>
  /// [files] - Optional file fields as Map<String, List<int>>
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map<String, dynamic>
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, List<int>>? files,
    Map<String, String>? headers,
  }) async {
    try {
      final url = _getFullUrl(endpoint);
      print('POST Multipart Request: $url');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      final token = await _authService?.getStoredToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add additional headers (excluding Content-Type as it's set by multipart)
      if (headers != null) {
        headers.forEach((key, value) {
          if (key.toLowerCase() != 'content-type') {
            request.headers[key] = value;
          }
        });
      }

      // Add form fields
      if (fields != null) {
        fields.forEach((key, value) {
          request.fields[key] = value;
        });
      }

      // Add file fields
      if (files != null) {
        files.forEach((key, value) {
          // Detect MIME type from file content
          final mimeType = _detectMimeType(value);
          final extension = _getExtensionFromMimeType(mimeType);
          final filename = '${key}$extension';

          request.files.add(
            http.MultipartFile.fromBytes(
              key,
              value,
              filename: filename,
              contentType: MediaType.parse(mimeType),
            ),
          );
        });
      }

      // Send the request
      final streamedResponse = await _client!.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService?.refresh() ?? false;
        if (refreshSuccess) {
          // Retry the request with new token
          final retryRequest = http.MultipartRequest('POST', Uri.parse(url));
          final newToken = await _authService?.getStoredToken();
          if (newToken != null && newToken.isNotEmpty) {
            retryRequest.headers['Authorization'] = 'Bearer $newToken';
          }

          // Re-add fields and files
          if (fields != null) {
            fields.forEach((key, value) {
              retryRequest.fields[key] = value;
            });
          }
          if (files != null) {
            files.forEach((key, value) {
              // Detect MIME type from file content
              final mimeType = _detectMimeType(value);
              final extension = _getExtensionFromMimeType(mimeType);
              final filename = '${key}$extension';

              retryRequest.files.add(
                http.MultipartFile.fromBytes(
                  key,
                  value,
                  filename: filename,
                  contentType: MediaType.parse(mimeType),
                ),
              );
            });
          }

          final retryStreamedResponse = await _client!.send(retryRequest);
          final retryResponse = await http.Response.fromStream(
            retryStreamedResponse,
          );
          await _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      await _handleResponse(response);
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

  /// Perform PATCH request with multipart/form-data
  ///
  /// [endpoint] - API endpoint (e.g., '/users/123' or 'users/123')
  /// [fields] - Form fields as Map<String, String>
  /// [files] - Optional file fields as Map<String, List<int>>
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map<String, dynamic>
  Future<Map<String, dynamic>> patchMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, List<int>>? files,
    Map<String, String>? headers,
  }) async {
    try {
      final url = _getFullUrl(endpoint);
      print('PATCH Multipart Request: $url');

      // Create multipart request
      final request = http.MultipartRequest('PATCH', Uri.parse(url));

      // Add authorization header
      final token = await _authService?.getStoredToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add additional headers (excluding Content-Type as it's set by multipart)
      if (headers != null) {
        headers.forEach((key, value) {
          if (key.toLowerCase() != 'content-type') {
            request.headers[key] = value;
          }
        });
      }

      // Add form fields
      if (fields != null) {
        fields.forEach((key, value) {
          request.fields[key] = value;
        });
      }

      // Add file fields
      if (files != null) {
        files.forEach((key, value) {
          // Detect MIME type from file content
          final mimeType = _detectMimeType(value);
          final extension = _getExtensionFromMimeType(mimeType);
          final filename = '${key}$extension';

          request.files.add(
            http.MultipartFile.fromBytes(
              key,
              value,
              filename: filename,
              contentType: MediaType.parse(mimeType),
            ),
          );
        });
      }

      // Send the request
      final streamedResponse = await _client!.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      // Handle 401 responses with token refresh
      if (response.statusCode == 401) {
        final refreshSuccess = await _authService?.refresh() ?? false;
        if (refreshSuccess) {
          // Retry the request with new token
          final retryRequest = http.MultipartRequest('PATCH', Uri.parse(url));
          final newToken = await _authService?.getStoredToken();
          if (newToken != null && newToken.isNotEmpty) {
            retryRequest.headers['Authorization'] = 'Bearer $newToken';
          }

          // Re-add fields and files
          if (fields != null) {
            fields.forEach((key, value) {
              retryRequest.fields[key] = value;
            });
          }
          if (files != null) {
            files.forEach((key, value) {
              // Detect MIME type from file content
              final mimeType = _detectMimeType(value);
              final extension = _getExtensionFromMimeType(mimeType);
              final filename = '${key}$extension';

              retryRequest.files.add(
                http.MultipartFile.fromBytes(
                  key,
                  value,
                  filename: filename,
                  contentType: MediaType.parse(mimeType),
                ),
              );
            });
          }

          final retryStreamedResponse = await _client!.send(retryRequest);
          final retryResponse = await http.Response.fromStream(
            retryStreamedResponse,
          );
          await _handleResponse(retryResponse);
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        } else {
          throw const UnauthorizedException(
            'Session expired. Please login again.',
          );
        }
      }

      await _handleResponse(response);
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

  /// Detect MIME type from file content (magic bytes)
  String _detectMimeType(List<int> bytes) {
    if (bytes.length < 4) return 'application/octet-stream';

    // Check for common image formats by magic bytes
    if (bytes.length >= 8) {
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }

      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }

      // GIF: 47 49 46 38 (GIF8)
      if (bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x38) {
        return 'image/gif';
      }

      // WebP: 52 49 46 46 ... 57 45 42 50
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
    }

    // Default to JPEG for unknown formats (most common for mobile images)
    return 'image/jpeg';
  }

  /// Get file extension from MIME type
  String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/jpeg':
        return '.jpg';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/bmp':
        return '.bmp';
      case 'image/tiff':
        return '.tiff';
      default:
        return '.jpg'; // Default to .jpg for unknown image types
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _client?.close();
  }
}
