import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigValidator {
  static void validateAndPrintConfig() {
    print('=== ENVIRONMENT CONFIGURATION VALIDATION ===');

    // Check required variables
    final requiredVars = [
      'SWAGGER_BASE_URL',
      'API_BASE_URL',
      'API_TIMEOUT',
      'SWAGGER_UI_URL',
    ];

    print('\n📋 Required Variables:');
    for (final varName in requiredVars) {
      final value = dotenv.env[varName];
      if (value != null && value.isNotEmpty) {
        print('✅ $varName: $value');
      } else {
        print('❌ $varName: MISSING');
      }
    }

    // Check authentication endpoints
    print('\n🔐 Authentication Endpoints:');
    final authEndpoints = [
      'AUTH_LOGIN_ENDPOINT',
      'AUTH_LOGOUT_ENDPOINT',
      'AUTH_REFRESH_ENDPOINT',
      'AUTH_REGISTER_ENDPOINT',
    ];

    for (final endpoint in authEndpoints) {
      final value = dotenv.env[endpoint];
      if (value != null && value.isNotEmpty) {
        final fullUrl = '${dotenv.env['API_BASE_URL']}$value';
        print('✅ $endpoint: $value → $fullUrl');
      } else {
        print('❌ $endpoint: MISSING');
      }
    }

    // Check business logic endpoints
    print('\n📦 Business Logic Endpoints:');
    final businessEndpoints = [
      'INVENTORY_ENDPOINT',
      'STAFF_ENDPOINT',
      'BORROWED_ITEMS_ENDPOINT',
      'HISTORY_ENDPOINT',
    ];

    for (final endpoint in businessEndpoints) {
      final value = dotenv.env[endpoint];
      if (value != null && value.isNotEmpty) {
        final fullUrl = '${dotenv.env['API_BASE_URL']}$value';
        print('✅ $endpoint: $value → $fullUrl');
      } else {
        print('❌ $endpoint: MISSING');
      }
    }

    // Check configuration flags
    print('\n⚙️ Configuration Flags:');
    final debugMode = dotenv.env['DEBUG_MODE'] == 'true';
    final swaggerLogging = dotenv.env['ENABLE_SWAGGER_LOGGING'] == 'true';
    final apiTimeout =
        int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

    print('✅ DEBUG_MODE: $debugMode');
    print('✅ ENABLE_SWAGGER_LOGGING: $swaggerLogging');
    print('✅ API_TIMEOUT: ${apiTimeout}ms');

    // Check for potential issues
    print('\n⚠️ Potential Issues:');
    final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final swaggerBaseUrl = dotenv.env['SWAGGER_BASE_URL'] ?? '';

    if (apiBaseUrl == swaggerBaseUrl) {
      print('⚠️ API_BASE_URL and SWAGGER_BASE_URL are the same');
      print('   Consider if API_BASE_URL should include /api path');
    }

    if (apiBaseUrl.contains('localhost') && !apiBaseUrl.contains('http://')) {
      print('⚠️ localhost URL should include http:// protocol');
    }

    if (apiTimeout < 10000) {
      print('⚠️ API_TIMEOUT is quite low (${apiTimeout}ms)');
    }

    print('\n=== VALIDATION COMPLETE ===');
  }

  static Map<String, String> getFullEndpointUrls() {
    final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    return {
      'login':
          '$apiBaseUrl${dotenv.env['AUTH_LOGIN_ENDPOINT'] ?? '/auth/login'}',
      'logout':
          '$apiBaseUrl${dotenv.env['AUTH_LOGOUT_ENDPOINT'] ?? '/auth/logout'}',
      'refresh':
          '$apiBaseUrl${dotenv.env['AUTH_REFRESH_ENDPOINT'] ?? '/auth/refresh'}',
      'register':
          '$apiBaseUrl${dotenv.env['AUTH_REGISTER_ENDPOINT'] ?? '/auth/register'}',
      'inventory':
          '$apiBaseUrl${dotenv.env['INVENTORY_ENDPOINT'] ?? '/inventory'}',
      'staff': '$apiBaseUrl${dotenv.env['STAFF_ENDPOINT'] ?? '/staff'}',
      'borrowedItems':
          '$apiBaseUrl${dotenv.env['BORROWED_ITEMS_ENDPOINT'] ?? '/borrowed-items'}',
      'history': '$apiBaseUrl${dotenv.env['HISTORY_ENDPOINT'] ?? '/history'}',
    };
  }
}

