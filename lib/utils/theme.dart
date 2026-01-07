import 'package:flutter/material.dart';

class AppTheme {
  // Colores oficiales SENA
  static const Color senaPrimary = Color(0xFF39A900);
  static const Color senaSecondary = Color(0xFF333333);
  static const Color senaBackground = Color(0xFFF5F5F5);
  static const Color senaWhite = Color(0xFFFFFFFF);
  static const Color senaError = Color(0xFFD32F2F);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: senaPrimary,
      scaffoldBackgroundColor: senaBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: senaPrimary,
        primary: senaPrimary,
        secondary: senaSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: senaPrimary,
        foregroundColor: senaWhite,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: senaPrimary,
          foregroundColor: senaWhite,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: senaPrimary, width: 2),
        ),
      ),
    );
  }
}
