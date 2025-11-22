import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../welcome/welcome_screen.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _loginError; // Track login errors

  @override
  void initState() {
    super.initState();
    // Initialize auth state when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initializeAuth();
    });
  }

  void _attemptLogin() async {
    // Clear previous login error
    setState(() {
      _loginError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(username, password);

    if (success) {
      if (mounted) {
        // Navigate to welcome screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
      if (mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Login failed';

        // Check if it's a CORS error - show dialog for this
        if (errorMessage.contains('CORS') ||
            errorMessage.contains('ERR_FAILED')) {
          _showCorsErrorDialog(context);
        } else {
          // Show error snackbar for validation/auth errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _openFacebookPage() async {
    final Uri facebookUrl = Uri.parse('https://www.facebook.com/aclcmandaueph');
    try {
      if (await canLaunchUrl(facebookUrl)) {
        await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Facebook page'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Facebook page: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCardWidth = screenWidth > 600 ? 450.0 : screenWidth * 0.9;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF338AFF),
              Color(0xFF1E5FCC),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxCardWidth),
                        child: Card(
                          elevation: 8,
                          shadowColor: Colors.black45,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Logo
                                  GestureDetector(
                                    onTap: _openFacebookPage,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: SizedBox(
                                        height: 80,
                                        child: Image.asset(
                                          'assets/icons/aclcLOGO.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Title
                                  const Text(
                                    'Technical Assets\nManagement',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF1E5FCC),
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to continue',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  // Username
                                  TextFormField(
                                    controller: _usernameController,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      // Show login error on username field
                                      if (_loginError != null) {
                                        return _loginError;
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      hintText: 'Username',
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: Colors.grey[600],
                                      ),
                                      hintStyle: TextStyle(
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                        horizontal: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF338AFF),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      hintText: 'Password',
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Colors.grey[600],
                                      ),
                                      hintStyle: TextStyle(
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                        horizontal: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF338AFF),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Login button with loading state
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      return SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: authProvider.isLoading
                                              ? null
                                              : _attemptLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF338AFF),
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: Colors.grey[300],
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                          ),
                                          child: authProvider.isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Login',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),  // Column
                            ),  // Form
                          ),  // Container
                        ),  // Card
                      ),  // ConstrainedBox
                    ),  // Center
                  ),  // Padding
                ),  // SingleChildScrollView
              ),  // Center
            ),
          ),
    );
  }

  void _showCorsErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('CORS Error'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This error occurs because your Flutter web app and API are running on different ports.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Text('Solutions:'),
                const SizedBox(height: 8),
                const Text(
                  '1. Configure CORS on your API server (Recommended)',
                ),
                const Text('2. Run Flutter as desktop/mobile app instead'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For ASP.NET Core, add this to Program.cs:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'builder.Services.AddCors(options => {\n'
                        '  options.AddPolicy("AllowFlutterWeb", policy => {\n'
                        '    policy.WithOrigins("http://localhost:60546")\n'
                        '          .AllowAnyMethod()\n'
                        '          .AllowAnyHeader()\n'
                        '          .AllowCredentials();\n'
                        '  });\n'
                        '});\n\n'
                        'app.UseCors("AllowFlutterWeb");',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAlternativeRunOptions(context);
              },
              child: const Text('Run as Desktop'),
            ),
          ],
        );
      },
    );
  }

  void _showAlternativeRunOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alternative Run Options'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Run your Flutter app as desktop/mobile to avoid CORS:'),
              SizedBox(height: 16),
              Text('• Desktop: flutter run -d windows'),
              Text('• Mobile: flutter run -d android'),
              Text('• iOS: flutter run -d ios'),
              SizedBox(height: 8),
              Text(
                'Desktop and mobile apps don\'t have CORS restrictions.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
