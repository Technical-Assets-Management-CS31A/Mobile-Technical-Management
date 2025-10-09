import 'package:flutter_dotenv/flutter_dotenv.dart';

class SwaggerHelper {
  // Get API base URL
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://your-swagger-api.com/api/v1';

  // Get Swagger base URL
  static String get swaggerBaseUrl =>
      dotenv.env['SWAGGER_BASE_URL'] ?? 'https://your-swagger-api.com';

  // Get Swagger UI URL
  static String get swaggerUiUrl =>
      dotenv.env['SWAGGER_UI_URL'] ??
      'https://your-swagger-api.com/swagger-ui.html';

  // Get API timeout
  static int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  // Check if debug mode is enabled
  static bool get isDebugMode => dotenv.env['DEBUG_MODE'] == 'true';

  // Check if Swagger logging is enabled
  static bool get enableSwaggerLogging =>
      dotenv.env['ENABLE_SWAGGER_LOGGING'] == 'true';

  // Get app name
  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'Technical Assets Management';

  // Get app version
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  // Get authentication endpoints
  static String get loginEndpoint =>
      dotenv.env['AUTH_LOGIN_ENDPOINT'] ?? '/auth/login';

  static String get logoutEndpoint =>
      dotenv.env['AUTH_LOGOUT_ENDPOINT'] ?? '/auth/logout';

  static String get refreshEndpoint =>
      dotenv.env['AUTH_REFRESH_ENDPOINT'] ?? '/auth/refresh';

  static String get registerEndpoint =>
      dotenv.env['AUTH_REGISTER_ENDPOINT'] ?? '/auth/register';

  // Get business logic endpoints
  static String get inventoryEndpoint =>
      dotenv.env['INVENTORY_ENDPOINT'] ?? '/inventory';

  static String get staffEndpoint => dotenv.env['STAFF_ENDPOINT'] ?? '/staff';

  static String get borrowedItemsEndpoint =>
      dotenv.env['BORROWED_ITEMS_ENDPOINT'] ?? '/borrowed-items';

  static String get historyEndpoint =>
      dotenv.env['HISTORY_ENDPOINT'] ?? '/history';

  // Build full URL for an endpoint
  static String buildUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  // Build Swagger UI URL for a specific endpoint
  static String buildSwaggerUiUrl(String endpoint) {
    return '$swaggerUiUrl#/$endpoint';
  }

  // Get common headers for API requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get headers with authorization
  static Map<String, String> getHeadersWithAuth(String token) {
    final headers = Map<String, String>.from(defaultHeaders);
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Log API information if logging is enabled
  static void logApiInfo(
    String method,
    String url, {
    String? body,
    String? response,
    int? statusCode,
  }) {
    if (enableSwaggerLogging) {
      print('=== SWAGGER API INFO ===');
      print('Method: $method');
      print('URL: $url');
      if (body != null) print('Request Body: $body');
      if (response != null) print('Response: $response');
      if (statusCode != null) print('Status Code: $statusCode');
      print('========================');
    }
  }

  // Validate environment configuration
  static Map<String, String> validateConfiguration() {
    final issues = <String, String>{};

    if (apiBaseUrl.contains('your-swagger-api.com')) {
      issues['API_BASE_URL'] = 'Please update API_BASE_URL in .env file';
    }

    if (swaggerBaseUrl.contains('your-swagger-api.com')) {
      issues['SWAGGER_BASE_URL'] =
          'Please update SWAGGER_BASE_URL in .env file';
    }

    return issues;
  }

  // Get configuration summary
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'apiBaseUrl': apiBaseUrl,
      'swaggerBaseUrl': swaggerBaseUrl,
      'swaggerUiUrl': swaggerUiUrl,
      'apiTimeout': apiTimeout,
      'isDebugMode': isDebugMode,
      'enableSwaggerLogging': enableSwaggerLogging,
      'appName': appName,
      'appVersion': appVersion,
      'endpoints': {
        'login': loginEndpoint,
        'logout': logoutEndpoint,
        'refresh': refreshEndpoint,
        'register': registerEndpoint,
        'inventory': inventoryEndpoint,
        'staff': staffEndpoint,
        'borrowedItems': borrowedItemsEndpoint,
        'history': historyEndpoint,
      },
    };
  }
}

