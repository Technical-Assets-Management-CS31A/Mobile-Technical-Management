import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: const Color(AppConstants.primaryColor),
        onPrimary: Colors.white,
        secondary: const Color(AppConstants.secondaryColor),
        onSecondary: Colors.white,
        error: const Color(AppConstants.errorColor),
        onError: Colors.white,
        surface: const Color(AppConstants.neutral50),
        onSurface: const Color(AppConstants.neutral900),
        surfaceContainerHighest: const Color(AppConstants.neutral100),
        surfaceBright: Colors.white,
        surfaceDim: const Color(AppConstants.neutral100),
        outline: const Color(AppConstants.neutral300),
        outlineVariant: const Color(AppConstants.neutral200),
        shadow: Colors.black.withOpacity(0.25),
        scrim: Colors.black54,
        tertiary: const Color(AppConstants.accentColor),
        onTertiary: const Color(0xFF1A1A1A),
        primaryContainer: const Color(AppConstants.primaryColorLight),
        onPrimaryContainer: Colors.white,
        secondaryContainer: const Color(0xFFE6F6FF),
        onSecondaryContainer: const Color(AppConstants.primaryColorDark),
      ),
      scaffoldBackgroundColor: const Color(AppConstants.neutral50),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        shadowColor: Colors.black.withOpacity(0.08),
        margin: const EdgeInsets.all(AppConstants.smallPadding),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(AppConstants.neutral100),
        labelStyle: const TextStyle(color: Color(AppConstants.neutral800)),
        selectedColor: const Color(AppConstants.primaryColor).withOpacity(0.1),
        secondarySelectedColor: const Color(
          AppConstants.secondaryColor,
        ).withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(AppConstants.neutral200)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(AppConstants.primaryColor),
        unselectedItemColor: Color(AppConstants.neutral600),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(height: 1.3),
        bodyMedium: TextStyle(height: 1.35),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: const Color(AppConstants.primaryColor),
        onPrimary: Colors.white,
        secondary: const Color(AppConstants.secondaryColor),
        onSecondary: Colors.white,
        error: const Color(AppConstants.errorColor),
        onError: Colors.white,
        surface: const Color(0xFF1A1A1A),
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF3A3A3A),
        surfaceBright: const Color(0xFF3A3A3A),
        surfaceDim: const Color(0xFF1A1A1A),
        outline: const Color(0xFF404040),
        outlineVariant: const Color(0xFF333333),
        shadow: Colors.black.withOpacity(0.5),
        scrim: Colors.black87,
        tertiary: const Color(AppConstants.accentColor),
        onTertiary: Colors.white,
        primaryContainer: const Color(AppConstants.primaryColorDark),
        onPrimaryContainer: Colors.white,
        secondaryContainer: const Color(0xFF1A3A4A),
        onSecondaryContainer: const Color(AppConstants.primaryColorLight),
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF3A3A3A),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
        margin: const EdgeInsets.all(AppConstants.smallPadding),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF3A3A3A),
        labelStyle: const TextStyle(color: Colors.white),
        selectedColor: const Color(AppConstants.primaryColor).withOpacity(0.2),
        secondarySelectedColor: const Color(
          AppConstants.secondaryColor,
        ).withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF404040)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF3A3A3A),
        selectedItemColor: Color(AppConstants.primaryColor),
        unselectedItemColor: Color(0xFF888888),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(height: 1.3),
        bodyMedium: TextStyle(height: 1.35),
      ),
    );
  }
}
