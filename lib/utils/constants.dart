// App constants
import 'package:flutter/material.dart';

class AppConstants {
  // Colors - ACLC Theme
  // Core brand blues
  static const int primaryColor = 0xFF003A8C; // Deep ACLC blue
  static const int primaryColorLight = 0xFF145FC7;
  static const int primaryColorDark = 0xFF00245A;

  static const int secondaryColor = 0xFF00A3FF; // Accent sky blue
  static const int accentColor = 0xFFFFC107; // Gold accent for highlights

  // Semantic
  static const int successColor = 0xFF10B981;
  static const int warningColor = 0xFFF59E0B;
  static const int errorColor = 0xFFEF4444;

  // Neutrals
  static const int neutral900 = 0xFF0F172A;
  static const int neutral800 = 0xFF1F2937;
  static const int neutral700 = 0xFF374151;
  static const int neutral600 = 0xFF4B5563;
  static const int neutral500 = 0xFF6B7280;
  static const int neutral400 = 0xFF9CA3AF;
  static const int neutral300 = 0xFFD1D5DB;
  static const int neutral200 = 0xFFE5E7EB;
  static const int neutral100 = 0xFFF3F4F6;
  static const int neutral50 = 0xFFF8FAFC;

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border radius
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 20.0;

  // Text sizes
  static const double smallTextSize = 12.0;
  static const double defaultTextSize = 14.0;
  static const double largeTextSize = 18.0;
  static const double titleTextSize = 24.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 1000);

  // Helpers
  static MaterialColor primarySwatch() {
    return const MaterialColor(primaryColor, <int, Color>{
      50: Color(0xFFE6EDF7),
      100: Color(0xFFC3D5EE),
      200: Color(0xFF9EBAE2),
      300: Color(0xFF799ED6),
      400: Color(0xFF5D8ACA),
      500: Color(primaryColor),
      600: Color(0xFF0D4D9F),
      700: Color(0xFF0A3E80),
      800: Color(0xFF072E60),
      900: Color(0xFF041F41),
    });
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number';
    }

    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if exactly 10 digits
    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits (no spaces, dashes, or other characters)';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    // Check for special characters
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }

    return null;
  }
}
