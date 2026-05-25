import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF1A1410);
  static const Color card = Color(0xFF2A2018);
  static const Color accent = Color(0xFFD4820A);
  static const Color textPrimary = Color(0xFFF5E6C8);
  static const Color textMuted = Color(0xFF8B7355);

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(primary: accent, surface: card),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: accent,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: textPrimary)),
  );
}
