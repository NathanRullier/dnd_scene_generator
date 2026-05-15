import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      brightness: Brightness.dark,
      surface: const Color(0xFF1A1A2E),
      primary: const Color(0xFF8B5CF6),
      secondary: const Color(0xFFD946EF),
      tertiary: const Color(0xFFF59E0B),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F23),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A2E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF16162A),
      elevation: 0,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF16162A),
      indicatorColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF8B5CF6),
      thumbColor: const Color(0xFF8B5CF6),
      inactiveTrackColor: const Color(0xFF2A2A4A),
      overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
    ),
  );
}
