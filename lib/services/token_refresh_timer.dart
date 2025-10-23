import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Service to handle automatic refresh token requests every 10 minutes
class TokenRefreshTimer {
  static final TokenRefreshTimer _instance = TokenRefreshTimer._internal();
  factory TokenRefreshTimer() => _instance;
  TokenRefreshTimer._internal();

  Timer? _refreshTimer;
  AuthService? _authService;
  bool _isRunning = false;
  static const Duration _refreshInterval = Duration(minutes: 10);

  /// Set the AuthService instance (to avoid circular dependency)
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  /// Start the automatic refresh token timer
  Future<void> start() async {
    if (_isRunning) {
      debugPrint('Token refresh timer is already running');
      return;
    }

    // Check if user is logged in before starting timer
    if (_authService == null || !(await _authService!.isLoggedIn())) {
      debugPrint('User not logged in, not starting refresh timer');
      return;
    }

    _isRunning = true;
    debugPrint('🔄 Starting token refresh timer (every 10 minutes)');

    _refreshTimer = Timer.periodic(_refreshInterval, (timer) async {
      await _performRefresh();
    });
  }

  /// Stop the automatic refresh token timer
  void stop() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null;
    }
    _isRunning = false;
    debugPrint('⏹️ Token refresh timer stopped');
  }

  /// Check if the timer is currently running
  bool get isRunning => _isRunning;

  /// Perform the actual token refresh
  Future<void> _performRefresh() async {
    try {
      debugPrint('🔄 Attempting automatic token refresh...');

      // Check if AuthService is available
      if (_authService == null) {
        debugPrint('AuthService not available, stopping refresh timer');
        stop();
        return;
      }

      // Check if user is still logged in
      if (!(await _authService!.isLoggedIn())) {
        debugPrint('User no longer logged in, stopping refresh timer');
        stop();
        return;
      }

      // Check if token is already expired
      if (await _authService!.isTokenExpired()) {
        debugPrint('Token already expired, stopping refresh timer');
        stop();
        return;
      }

      // Perform the refresh using the mobile endpoint
      final result = await _authService!.refresh();

      if (result) {
        debugPrint('✅ Automatic token refresh successful');
      } else {
        debugPrint('❌ Automatic token refresh failed, stopping timer');
        stop();
      }
    } catch (e) {
      debugPrint('❌ Error during automatic token refresh: $e');
      // Don't stop the timer on error, just log it
    }
  }

  /// Restart the timer (useful when user logs in again)
  Future<void> restart() async {
    stop();
    await start();
  }

  /// Get the time until next refresh
  Duration? getTimeUntilNextRefresh() {
    if (!_isRunning || _refreshTimer == null) {
      return null;
    }

    // Calculate remaining time based on when the timer was started
    // This is an approximation since we don't track the exact start time
    return _refreshInterval;
  }

  /// Dispose of the timer (call this when the app is being disposed)
  void dispose() {
    stop();
  }
}
