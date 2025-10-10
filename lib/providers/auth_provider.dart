import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthService _authService;
  bool _isInitialized = false;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _refreshToken;
  String? _username;
  String? _userEmail;
  String? _userRole;
  String? _userId;
  String? _userStatus;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get userId => _userId;
  String? get userStatus => _userStatus;
  String? get errorMessage => _errorMessage;

  // Initialize auth state from storage
  Future<void> initializeAuth() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Initialize AuthService first
      _authService = AuthService();
      await _authService.initialize();
      _isInitialized = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final username = prefs.getString('username');
      final userEmail = prefs.getString('user_email');
      final userRole = prefs.getString('user_role');
      final userId = prefs.getString('user_id');
      final userStatus = prefs.getString('user_status');

      // Check if user is logged in and has valid tokens
      if (token != null && refreshToken != null && username != null) {
        _accessToken = token;
        _refreshToken = refreshToken;
        _username = username;
        _userEmail = userEmail;
        _userRole = userRole;
        _userId = userId;
        _userStatus = userStatus;
        _isAuthenticated = true;
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication: $e';
      print('AuthProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login method
  Future<bool> login(String identifier, String password) async {
    if (!_isInitialized) {
      await initializeAuth();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        identifier: identifier,
        password: password,
      );

      if (result['success'] == true) {
        final userData = result['data'] as Map<String, dynamic>;

        // Debug logging
        print('🔍 Login Response Data: $userData');
        print('🔍 Data type: ${userData.runtimeType}');
        print('🔍 Data keys: ${userData.keys}');

        // Extract tokens from response for Bearer authentication
        _accessToken = userData['accessToken'];
        _refreshToken = userData['refreshToken'];

        // Extract user info from nested user object
        final user = userData['user'] ?? userData;
        _username = user['username'] ?? identifier;
        _userEmail = user['email'];
        _userRole = user['userRole'] ?? user['role'];
        _userId = user['id'];
        _userStatus = user['status'];

        // Debug logging - user info only
        print('👤 User: $_username ($_userRole)');

        _isAuthenticated = true;

        // Save to persistent storage
        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('access_token', _accessToken!);
        }
        if (_refreshToken != null) {
          await prefs.setString('refresh_token', _refreshToken!);
        }
        if (_username != null) {
          await prefs.setString('username', _username!);
        }
        if (_userEmail != null) {
          await prefs.setString('user_email', _userEmail!);
        }
        if (_userRole != null) {
          await prefs.setString('user_role', _userRole!);
        }
        if (_userId != null) {
          await prefs.setString('user_id', _userId!);
        }
        if (_userStatus != null) {
          await prefs.setString('user_status', _userStatus!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Call logout API - the new AuthService handles token management internally
      await _authService.logout();

      // Clear local state
      _isAuthenticated = false;
      _accessToken = null;
      _refreshToken = null;
      _username = null;
      _userEmail = null;
      _userRole = null;
      _userId = null;
      _userStatus = null;
      _errorMessage = null;

      // Clear persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('username');
      await prefs.remove('user_email');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('user_status');
    } catch (e) {
      _errorMessage = 'Logout failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh token method
  Future<bool> refreshAccessToken() async {
    try {
      // Use the new AuthService refresh method that returns a boolean
      final success = await _authService.refresh();

      if (success) {
        // Get the updated token from AuthService
        final newToken = await _authService.getStoredToken();
        if (newToken != null) {
          _accessToken = newToken;

          // Update stored token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);

          notifyListeners();
          return true;
        }
      }

      // Refresh failed, logout user
      await logout();
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if user is authenticated
  bool get isLoggedIn => _isAuthenticated && _accessToken != null;
}
