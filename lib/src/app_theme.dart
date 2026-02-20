import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color backgroundLight = Color(0xFFF3F4F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color neonBlue = Color(0xFF0EA5E9);
  static const Color neonGold = Color(0xFFF59E0B);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color onlineGreen = Color(0xFF22C55E);

  static ThemeData lightTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: neonBlue,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.chakraPetchTextTheme().apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
    );
  }

  static ThemeData darkTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: neonBlue,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.chakraPetchTextTheme(ThemeData.dark().textTheme),
    );
  }
}
