import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors matching the screenshots
  static const Color background = Color(0xFFFAF6F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceCream = Color(0xFFF7F2EB);
  static const Color surfaceWarm = Color(0xFFF3EBE1);
  
  static const Color primaryTerracotta = Color(0xFF8C4A3E); // Primary brown-red button/accent
  static const Color primaryDark = Color(0xFF6E372D);
  static const Color mustardGold = Color(0xFFCBA034); // Yellow-gold badge/active pill
  static const Color mustardDark = Color(0xFF8C6E15);
  static const Color softCoral = Color(0xFFFF8A80); // Coral salmon pill highlight
  static const Color softPink = Color(0xFFFFC0BD);
  static const Color oliveGreen = Color(0xFF6B701D); // Completed step check color
  static const Color oliveLight = Color(0xFFEFF3DB);

  static const Color textPrimary = Color(0xFF2A2421);
  static const Color textSecondary = Color(0xFF756D69);
  static const Color textMuted = Color(0xFFA59D96);

  static const Color borderLight = Color(0xFFECE4D9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryTerracotta,
      colorScheme: const ColorScheme.light(
        primary: primaryTerracotta,
        secondary: mustardGold,
        surface: cardBg,
        onPrimary: Colors.white,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primaryTerracotta,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTerracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }
}
