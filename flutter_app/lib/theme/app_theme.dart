// Centralized design-token theme for BP Mitra.
// Implements the minimalist high-contrast grid design:
//   • Dark Blue (#1543A4) header surfaces
//   • Pure White (#FFFFFF) body canvas
//   • Soft blue pill backgrounds for card icons
//   • Dark slate typography

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colors ─────────────────────────────────────────────
  static const Color darkBlue      = Color(0xFF1543A4);
  static const Color white         = Color(0xFFFFFFFF);
  static const Color softBluePill  = Color(0xFFE8EEFF);   // icon pill bg
  static const Color darkSlate     = Color(0xFF1A2340);   // primary text
  static const Color midSlate      = Color(0xFF4A5568);   // secondary text
  static const Color lightSlate    = Color(0xFF718096);   // tertiary/caption
  static const Color cardShadow    = Color(0x1A1543A4);   // 10% brand shadow
  static const Color errorRed      = Color(0xFFE53E3E);
  static const Color successGreen  = Color(0xFF38A169);
  static const Color warningAmber  = Color(0xFFD69E2E);
  static const Color sodiumRed     = Color(0xFFE53E3E);   // >1500mg hard stop

  // ── Gradient for header blocks ────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1543A4), Color(0xFF1E56C4)],
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkBlue,
      primary: darkBlue,
      secondary: softBluePill,
      error: errorRed,
      surface: white,
      onPrimary: white,
      onSecondary: darkBlue,
      onSurface: darkSlate,
    ),
    fontFamily: 'Inter',

    // ── AppBar matches Dark Blue header block spec ────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBlue,
      foregroundColor: white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: white,
        letterSpacing: -0.3,
      ),
    ),

    // ── Card: white canvas, subtle blue-tinted shadow ─────────
    cardTheme: CardThemeData(
      color: white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    // ── Text styles mapped to Inter weight scale ──────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: darkSlate, letterSpacing: -1),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: darkSlate, letterSpacing: -0.8),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkSlate, letterSpacing: -0.3),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: darkSlate, letterSpacing: -0.2),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: midSlate),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: darkSlate, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: midSlate, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: lightSlate, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: white, letterSpacing: 0.4),
    ),

    // ── ElevatedButton: Dark Blue fill ────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkBlue,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),

    // ── Input fields: clean white with blue focus border ──────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7F9FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: midSlate, fontSize: 14),
      hintStyle: const TextStyle(color: lightSlate, fontSize: 14),
    ),
  );
}
