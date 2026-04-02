import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF1F4A78);
  static const Color navyDark = Color(0xFF173A61);
  static const Color teal = Color(0xFF16A7AF);
  static const Color tealLight = Color(0xFF42C6CD);
  static const Color gold = Color(0xFFF7B733);
  static const Color correctGreen = Color(0xFF44B96A);
  static const Color incorrectRed = Color(0xFFE45B5B);
  static const Color pageBackground = Color(0xFFF1F4F8);

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        secondary: navy,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: pageBackground,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: navyDark,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: navyDark),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: navy),
        bodyMedium: TextStyle(color: Color(0xFF4D5F73)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 54),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 50),
          side: const BorderSide(color: navy),
          foregroundColor: navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
    return base;
  }
}
