import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';

/// Example LoginPage widget demonstrating how to use AuthService
/// This is a complete example showing proper integration with the REST API service
class ExampleLoginPage extends StatefulWidget {
  const ExampleLoginPage({super.key});

  @override
  State<ExampleLoginPage> createState() => _ExampleLoginPageState();
}

class _ExampleLoginPageState extends State<ExampleLoginPage> {
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoginMode = true; // Toggle between login and register

  // AuthService instance
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _initializeAuthService();
  }

  /// Initialize the AuthService
  Future<void> _initializeAuthService() async {
    try {
      await _authService.initialize();
      print('AuthService initialized successfully');
    } catch (e) {
      print('Error initializing AuthService: $e');
      _showErrorSnackBar('Failed to initialize authentication service');
    }
  }

  /// Handle login attempt
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        _showSuccessSnackBar('Login successful!');

        // Navigate to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(result['error'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      _showErrorSnackBar('An unexpected error occurred during login');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle registration attempt
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim().isNotEmpty
            ? _firstNameController.text.trim()
            : null,
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
      );

      if (result['success'] == true) {
        _showSuccessSnackBar('Registration successful! Please login.');

        // Switch to login mode
        setState(() {
          _isLoginMode = true;
        });

        // Clear password fields
        _passwordController.clear();
      } else {
        _showErrorSnackBar(result['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      _showErrorSnackBar('An unexpected error occurred during registration');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Test API connection
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.testConnection();
      if (result['success'] == true) {
        _showSuccessSnackBar('API connection successful!');
      } else {
        _showErrorSnackBar(result['error'] ?? 'API connection failed');
      }
    } catch (e) {
      print('Connection test error: $e');
      _showErrorSnackBar('Failed to test API connection');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show success message
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF338AFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isLoginMode ? 'Login' : 'Register',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Test connection button
          IconButton(
            onPressed: _isLoading ? null : _testConnection,
            icon: const Icon(Icons.wifi, color: Colors.white),
            tooltip: 'Test API Connection',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: SizedBox(
                        height: 80,
                        child: Image.asset(
                          'assets/icons/aclcLOGO.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      _isLoginMode
                          ? 'Technical Assets\nManagement'
                          : 'Create Account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    if (!_isLoginMode) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Register an admin account to manage the system',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Registration fields (only shown in register mode)
                    if (!_isLoginMode) ...[
                      _buildTextField(
                        controller: _firstNameController,
                        hintText: 'First Name (Optional)',
                        validator: null, // Optional field
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _lastNameController,
                        hintText: 'Last Name (Optional)',
                        validator: null, // Optional field
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Username field
                    _buildTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your username';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_isLoginMode ? _handleLogin : _handleRegister),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Text(_isLoginMode ? 'Login' : 'Register'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Toggle between login and register
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                // Clear form when switching modes
                                _passwordController.clear();
                                if (_isLoginMode) {
                                  _emailController.clear();
                                  _firstNameController.clear();
                                  _lastNameController.clear();
                                }
                              });
                            },
                      child: Text(
                        _isLoginMode
                            ? 'Don\'t have an account? Register'
                            : 'Already have an account? Login',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // API Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'API Configuration:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Base URL: ${_authService.baseUrl}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Swagger UI: ${_authService.swaggerUiUrl}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a text field with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: const TextStyle(fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}
