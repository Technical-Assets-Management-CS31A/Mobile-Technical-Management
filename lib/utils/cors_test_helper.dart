import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CorsTestHelper {
  // Test CORS preflight request
  static Future<Map<String, dynamic>> testCorsPreflight() async {
    try {
      final apiBaseUrl =
          dotenv.env['API_BASE_URL'] ?? 'http://localhost:5278/scalar/api/v1';
      final loginUrl = '$apiBaseUrl/auth/login';

      // Make an OPTIONS request (preflight)
      final response = await http.Request('OPTIONS', Uri.parse(loginUrl))
        ..headers.addAll({
          'Origin': 'http://localhost:60546',
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'Content-Type',
        });
      final streamedResponse = await response.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // Create a mock response object with the status code and headers
      final mockResponse = http.Response(
        responseBody,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
      );

      final corsHeaders = {
        'Access-Control-Allow-Origin':
            mockResponse.headers['access-control-allow-origin'],
        'Access-Control-Allow-Methods':
            mockResponse.headers['access-control-allow-methods'],
        'Access-Control-Allow-Headers':
            mockResponse.headers['access-control-allow-headers'],
        'Access-Control-Allow-Credentials':
            mockResponse.headers['access-control-allow-credentials'],
      };

      return {
        'success': mockResponse.statusCode == 200,
        'statusCode': mockResponse.statusCode,
        'corsHeaders': corsHeaders,
        'message': mockResponse.statusCode == 200
            ? 'CORS preflight successful!'
            : 'CORS preflight failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to test CORS: $e'};
    }
  }

  // Test actual API call
  static Future<Map<String, dynamic>> testApiCall() async {
    try {
      final apiBaseUrl =
          dotenv.env['API_BASE_URL'] ?? 'http://localhost:5278/scalar/api/v1';
      final loginUrl = '$apiBaseUrl/auth/login';

      // Make a test POST request
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://localhost:60546',
        },
        body: json.encode({'username': 'test', 'password': 'test'}),
      );

      return {
        'success': response.statusCode != 0, // Any response means CORS worked
        'statusCode': response.statusCode,
        'message': response.statusCode == 401
            ? 'CORS working! (401 = invalid credentials, but CORS passed)'
            : 'API call successful',
        'responseBody': response.body,
      };
    } catch (e) {
      return {'success': false, 'error': 'API call failed: $e'};
    }
  }

  // Get CORS configuration status
  static Map<String, dynamic> getCorsStatus() {
    return {
      'flutterOrigin': 'http://localhost:60546',
      'apiOrigin':
          dotenv.env['API_BASE_URL'] ?? 'http://localhost:5278/scalar/api/v1',
      'expectedCorsPolicy': 'AllowLocalhost',
      'description': 'Your CORS policy allows all localhost origins',
    };
  }
}
