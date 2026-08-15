import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class T {
  // TaskTeddy blue theme
  static const primary = Color(0xFF6384DB);
  static const primaryDark = Color(0xFF4F6FC5);
  static const primaryLight = Color(0xFFEAF0FF);
  static const accent = Color(0xFF829DE6);
  static const bg = Color(0xFFF6F8FF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDE6FF);
  static const divider = Color(0xFFEEF3FF);
  static const text1 = Color(0xFF1A1A1A);
  static const text2 = Color(0xFF4A4A4A);
  static const text3 = Color(0xFF8A8A8A);
  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFDCFCE7);
  static const yellow = Color(0xFFF59E0B);
  static const yellowLight = Color(0xFFFEF3C7);
  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFFEFF6FF);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEE2E2);
  static const gold = Color(0xFFFFD700);
  static const star = Color(0xFFF5A623);
  static const teal = Color(0xFF14B8A6);

  // ── Console tokens ("operational work app" identity) ──────
  // Structured dark header/panel surfaces express the brand blue
  // in a denser, data-forward, partner-ops style.
  // Header panel shades — now the brand-blue family (was dark navy) so any
  // direct use renders as the clean blue theme, matching panelGradient.
  static const panel = Color(0xFF6384DB);      // primary blue header
  static const panelDark = Color(0xFF4F6FC5);  // deeper blue
  static const panelAccent = Color(0xFF829DE6); // lighter blue highlight
  static const surface = Color(0xFFEEF1F8);    // cool structured neutral
  static const surfaceAlt = Color(0xFFE4E9F4); // slightly deeper neutral
  // Status-driven coding used consistently across the app.
  static const online = Color(0xFF16A34A);     // online / available
  static const pending = Color(0xFFF59E0B);    // pending / in-review
  static const offline = Color(0xFF94A3B8);    // offline / inactive
}

ThemeData buildTaskerTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: T.bg,
      colorScheme:
          ColorScheme.fromSeed(seedColor: T.primary, primary: T.primary),
      textTheme: GoogleFonts.nunitoTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: T.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: T.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: T.primary,
          side: const BorderSide(color: T.primary),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: T.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T.primary, width: 2)),
        hintStyle: GoogleFonts.nunito(color: T.text3, fontSize: 14),
      ),
    );
