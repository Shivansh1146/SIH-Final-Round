import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// SHAYAK-AI: Warm Organic & Accessible Design System
/// Replicates the exact tranquil sage, forest teal, warm terracotta,
/// and ivory aesthetic tailored for elderly cognitive care and caregiver clarity.
/// ============================================================================
class AppTheme {
  // Brand Palette
  static const Color background = Color(0xFFF4F7F4);          // Soft ivory/sage canvas
  static const Color surface = Color(0xFFFFFFFF);             // Pure white card surfaces
  static const Color surfaceSubtle = Color(0xFFF8FAF8);       // Subtle card background
  static const Color surfaceBorder = Color(0xFFE3ECE6);       // Crisp subtle border
  
  static const Color forestGreen = Color(0xFF134E3F);         // Primary brand dark green
  static const Color forestTealCard = Color(0xFF1B5A46);      // Hero activity card green
  static const Color forestTealDark = Color(0xFF0F3A2E);      // Deep forest header tone
  static const Color sageLight = Color(0xFFE7F0EA);           // Sage badge/card container
  static const Color sageBorder = Color(0xFFCDE0D4);          // Sage container outline
  
  static const Color warmTerracotta = Color(0xFFD97736);      // Accent warm terracotta / orange
  static const Color warmPeach = Color(0xFFFDE8D8);           // Peach button / pill surface
  static const Color warmPeachDark = Color(0xFFF5BD93);       // Darker peach border/hover
  static const Color warmOchre = Color(0xFFC86B32);           // Header gradient accent
  
  static const Color textPrimary = Color(0xFF15332B);         // High-contrast primary text
  static const Color textSecondary = Color(0xFF5A756C);       // Muted secondary text
  static const Color textLight = Color(0xFF8BA39A);           // Subtle captions
  
  static const Color pastelPink = Color(0xFFFDE8EC);          // Brain / activity chip
  static const Color pastelBlue = Color(0xFFEAF1FB);          // Lunch / info chip
  static const Color pastelYellow = Color(0xFFFEF7E0);        // Medicine / alert chip
  
  static const Color statusGreen = Color(0xFF22C55E);         // Live sync green dot
  static const Color alertCoral = Color(0xFFE63946);          // Alert indicator

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: forestGreen,
      canvasColor: background,
      cardColor: surface,

      colorScheme: const ColorScheme.light(
        primary: forestGreen,
        onPrimary: Colors.white,
        secondary: warmTerracotta,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: alertCoral,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 42.0,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 32.0,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 26.0,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18.0,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: surfaceBorder, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          backgroundColor: surface,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          side: const BorderSide(color: surfaceBorder, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
