// apps/customer_app/lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF070B14);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF06B6D4),
        brightness: Brightness.dark,
        background: background,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.5,
          height: 1.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: const Color.fromRGBO(6, 12, 24, 0.35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF06B6D4),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
    );
  }
}
