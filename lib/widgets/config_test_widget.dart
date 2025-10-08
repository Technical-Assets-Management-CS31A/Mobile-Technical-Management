import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/config_validator.dart';
import '../services/auth_service.dart';
import '../utils/cors_test_helper.dart';

class ConfigTestWidget extends StatefulWidget {
  const ConfigTestWidget({super.key});

  @override
  State<ConfigTestWidget> createState() => _ConfigTestWidgetState();
}

class _ConfigTestWidgetState extends State<ConfigTestWidget> {
  bool _isTestingConnection = false;
  String _connectionResult = '';
  bool _isTestingCors = false;
  String _corsResult = '';

  @override
  void initState() {
    super.initState();
    // Print configuration validation on widget init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConfigValidator.validateAndPrintConfig();
    });
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionResult = '';
    });

    try {
      final authService = AuthService();
      final result = await authService.testConnection();

      setState(() {
        _connectionResult = result['success']
            ? '✅ Connection successful!'
            : '❌ Connection failed: ${result['error']}';
      });
    } catch (e) {
      setState(() {
        _connectionResult = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _testCors() async {
    setState(() {
      _isTestingCors = true;
      _corsResult = '';
    });

    try {
      final result = await CorsTestHelper.testCorsPreflight();

      setState(() {
        if (result['success']) {
          _corsResult =
              '✅ CORS preflight successful!\n'
              'Status: ${result['statusCode']}\n'
              'Headers: ${result['corsHeaders']}';
        } else {
          _corsResult = '❌ CORS preflight failed: ${result['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _corsResult = '❌ CORS test error: $e';
      });
    } finally {
      setState(() {
        _isTestingCors = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Configuration Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildConfigRow(
                      'API Base URL',
                      dotenv.env['API_BASE_URL'] ?? 'Not set',
                    ),
                    _buildConfigRow(
                      'Swagger Base URL',
                      dotenv.env['SWAGGER_BASE_URL'] ?? 'Not set',
                    ),
                    _buildConfigRow(
                      'Swagger UI URL',
                      dotenv.env['SWAGGER_UI_URL'] ?? 'Not set',
                    ),
                    _buildConfigRow(
                      'API Timeout',
                      '${dotenv.env['API_TIMEOUT'] ?? '30000'}ms',
                    ),
                    _buildConfigRow(
                      'Debug Mode',
                      dotenv.env['DEBUG_MODE'] ?? 'false',
                    ),
                    _buildConfigRow(
                      'Swagger Logging',
                      dotenv.env['ENABLE_SWAGGER_LOGGING'] ?? 'false',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Full Endpoint URLs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔗 Full Endpoint URLs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...ConfigValidator.getFullEndpointUrls().entries.map(
                      (entry) => _buildConfigRow(entry.key, entry.value),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Connection Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Connection Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isTestingConnection
                            ? null
                            : _testApiConnection,
                        child: _isTestingConnection
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Testing...'),
                                ],
                              )
                            : const Text('Test API Connection'),
                      ),
                    ),
                    if (_connectionResult.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _connectionResult.contains('✅')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _connectionResult.contains('✅')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _connectionResult,
                          style: TextStyle(
                            color: _connectionResult.contains('✅')
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CORS Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 CORS Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your CORS Configuration:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('✅ Allows all localhost origins'),
                          const Text('✅ Allows all HTTP methods'),
                          const Text('✅ Allows all headers'),
                          const Text('✅ Allows credentials'),
                          const SizedBox(height: 8),
                          Text(
                            'Flutter Origin: http://localhost:60546',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isTestingCors ? null : _testCors,
                        child: _isTestingCors
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Testing CORS...'),
                                ],
                              )
                            : const Text('Test CORS Preflight'),
                      ),
                    ),
                    if (_corsResult.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _corsResult.contains('✅')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _corsResult.contains('✅')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _corsResult,
                          style: TextStyle(
                            color: _corsResult.contains('✅')
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Recommendations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendation(
                      'Check Swagger UI',
                      'Visit your Swagger UI to verify endpoint paths',
                      dotenv.env['SWAGGER_UI_URL'] ?? '',
                    ),
                    const SizedBox(height: 8),
                    _buildRecommendation(
                      'Verify API Structure',
                      'Ensure your API endpoints match the expected paths',
                      'Check if endpoints need /api prefix',
                    ),
                    const SizedBox(height: 8),
                    _buildRecommendation(
                      'Test Authentication',
                      'Try logging in to verify auth endpoints work',
                      'Use the login screen to test',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value.contains('Not set') ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String title, String description, String action) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(description),
          if (action.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              action,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
