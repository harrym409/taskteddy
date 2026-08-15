import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class C {
  // Brand - coral identity (#ff8f8f). `primary` is the brand hue used for
  // tints, icons, chips and highlights. `primaryDark` is a deeper coral used
  // for buttons, app bars and gradient ends so white text stays legible.
  static const primary = Color(0xFFFF6E6E);
  static const primaryDark = Color(0xFFEC5454);
  static const primaryLight = Color(0xFFFFE4E4);
  static const accent = Color(0xFFFF9A9A);

  // Deep coral for interactive surfaces that carry white text/icons (buttons,
  // app bar, header gradient) — keeps contrast readable against the light brand.
  static const brandInk = Color(0xFFEC5454);

  // Secondary accent — a warm amber, used sparingly for offers/badges so not
  // everything is coral (kept the old token names so existing usages still work).
  static const accent2 = Color(0xFFFFB020); // warm amber
  static const accent2Dark = Color(0xFFE0930C);
  static const accent2Light = Color(0xFFFFF3D6);

  // Shape rhythm — soft, rounded surfaces on an 8pt spacing grid.
  static const double rCard = 20;
  static const double rChip = 999;

  // Surfaces - warm neutrals to sit under the coral brand.
  static const bg = Color(0xFFFFF7F6);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFF3E1E1);
  static const divider = Color(0xFFF8ECEC);

  // Text - matched to Tasker app
  static const text1 = Color(0xFF1A1A1A);
  static const text2 = Color(0xFF4A4A4A);
  static const text3 = Color(0xFF8A8A8A);

  // Semantic
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
  static const orange = Color(0xFFFF6B35);
  
  // Greys
  static const grey1 = Color(0xFF9CA3AF);
  static const grey2 = Color(0xFF6B7280);
  static const grey3 = Color(0xFF4B5563);
  static const grey4 = Color(0xFF374151);
}

ThemeData buildCustomerTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: C.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: C.primary,
        primary: C.primary,
        surface: C.card,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: C.brandInk,
        foregroundColor: Colors.white,
        surfaceTintColor: C.brandInk,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.brandInk,
          foregroundColor: Colors.white,
          disabledBackgroundColor: C.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          // Comfortable horizontal padding so auto-width buttons never crowd
          // their label; a 52pt min height keeps a solid, professional tap area.
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          minimumSize: const Size(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: C.primary,
          side: const BorderSide(color: C.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(0, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: C.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.red)),
        hintStyle: GoogleFonts.poppins(color: C.text3, fontSize: 14),
      ),
    );
