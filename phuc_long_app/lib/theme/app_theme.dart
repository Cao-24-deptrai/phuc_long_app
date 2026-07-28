import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors for Phúc Long
  static const Color primaryColor = Color(0xFF0C5A30); // Forest Green
  static const Color accentColor = Color(0xFFC8A2C8);  // Pale purple or gold accent
  static const Color goldColor = Color(0xFFB89047);    // Brand gold accent
  static const Color backgroundColor = Color(0xFFFAF9F6); // Soft off-white
  static const Color cardColor = Colors.white;
  
  static const Color textDark = Color(0xFF1E293B);     // Slate 800
  static const Color textLight = Color(0xFF64748B);    // Slate 500
  static const Color dividerColor = Color(0xFFE2E8F0); // Slate 200

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: goldColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // Đổi font chữ mặc định của toàn app sang Be Vietnam Pro
      textTheme: GoogleFonts.beVietnamProTextTheme(
        TextTheme(
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
          displayMedium: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            color: textDark,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            color: textLight,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),
    );
  }
}

