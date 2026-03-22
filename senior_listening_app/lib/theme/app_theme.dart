import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFEDE8D7);    // Warm parchment cream
  static const Color primary = Color(0xFFD4683A);       // Deep rust orange
  static const Color secondary = Color(0xFF5C7A2E);     // Deep olive green
  static const Color text = Color(0xFF333333);          // Dark gray
  static const Color titleGreen = Color(0xFF4A6B24);    // Warm green for headline
  static const Color card = Color(0xFFFFFBF5);          // Off-white

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: card,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: titleGreen,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          color: text,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          color: text,
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return base.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(fontSize: 18),
      ),
    );
  }
}
