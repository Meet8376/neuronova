import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
// All colours are defined here only. Every widget should reference AppColors
// rather than hardcoding hex values, so a future re-theme is a one-line change.

class AppColors {
  AppColors._();

  // Primary — a warm teal that feels calm and trustworthy, not cold/clinical
  static const Color primary = Color(0xFF2A7B6F);
  static const Color primaryLight = Color(0xFF4CA99A);
  static const Color primaryDark = Color(0xFF1A5C53);

  // Accent — warm saffron, culturally familiar for Indian users
  static const Color accent = Color(0xFFE8A020);
  static const Color accentLight = Color(0xFFF5C45E);

  // Backgrounds
  static const Color scaffoldBg = Color(0xFFF5F2EE); // warm off-white, not harsh
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBgWarm = Color(0xFFFDF8F2);

  // Text — near-black, never pure #000000 (softer on aging eyes)
  static const Color textPrimary = Color(0xFF1C1C2E);
  static const Color textSecondary = Color(0xFF5A5A72);
  static const Color textHint = Color(0xFF9A9AB0);

  // Status colours — always paired with icon/text, never colour alone
  static const Color success = Color(0xFF2E7D5A);   // done
  static const Color warning = Color(0xFFD4760A);   // in-progress / snooze
  static const Color error = Color(0xFFC0392B);     // missed / alert
  static const Color info = Color(0xFF2A5C8A);      // upcoming

  // Surface shades
  static const Color divider = Color(0xFFE0DDD8);
  static const Color surfaceVariant = Color(0xFFEFEBE6);

  // Bottom nav
  static const Color navSelected = primary;
  static const Color navUnselected = Color(0xFFA0A0B8);

  // Word highlight in TTS mode
  static const Color wordHighlight = Color(0xFFFFE082); // warm yellow
  static const Color wordHighlightText = Color(0xFF1C1C2E);

  // Card border (subtle, used on login profile cards and selection cards)
  static const Color cardBorder = Color(0xFFE0DDD8);
}

// ─── Typography ───────────────────────────────────────────────────────────────
// All font sizes are intentionally large for elderly readability.
// We use Nunito — warm, rounded, highly legible.

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _nunito(double size, FontWeight weight, Color color) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color, height: 1.4);

  // Greeting headline: "Good Morning, Rajan"
  static TextStyle greeting(BuildContext ctx) => _nunito(
      28 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w700, AppColors.textPrimary);

  // Date text below greeting
  static TextStyle dateText(BuildContext ctx) => _nunito(
      20 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w500, AppColors.textSecondary);

  // Section headers
  static TextStyle sectionHeader(BuildContext ctx) => _nunito(
      22 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w700, AppColors.textPrimary);

  // Task / card title
  static TextStyle cardTitle(BuildContext ctx) => _nunito(
      20 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w600, AppColors.textPrimary);

  // Task / card subtitle (time, dose info)
  static TextStyle cardSubtitle(BuildContext ctx) => _nunito(
      17 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w400, AppColors.textSecondary);

  // Body text in game (the passage to memorise)
  static TextStyle gameText(BuildContext ctx) => _nunito(
      22 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w400, AppColors.textPrimary);

  // Live transcript text
  static TextStyle transcriptText(BuildContext ctx) => _nunito(
      18 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w400, AppColors.textSecondary);

  // General body text (content passages, spoken text display)
  static TextStyle body(BuildContext ctx) => _nunito(
      18 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w400, AppColors.textPrimary);

  // Button labels
  static TextStyle button(BuildContext ctx) => _nunito(
      20 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w700, Colors.white);

  // Score on results screen
  static TextStyle scoreLarge(BuildContext ctx) => _nunito(
      56 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w800, AppColors.textPrimary);

  // Badge text (status chips)
  static TextStyle badge(BuildContext ctx) => _nunito(
      14 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w600, Colors.white);

  // Small labels (e.g. "Added by admin")
  static TextStyle label(BuildContext ctx) =>
      _nunito(15 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w400, AppColors.textHint);

  // ── Login-specific tokens ────────────────────────────────────────────────

  // App name in the logo row ("CogniCare")
  static TextStyle appTitle(BuildContext ctx) =>
      _nunito(26 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w800, AppColors.textPrimary);

  // App tagline under title
  static TextStyle appTagline(BuildContext ctx) =>
      _nunito(15 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w500, AppColors.textSecondary);

  // "Who is using the app today?" headline on login screen
  static TextStyle loginHeadline(BuildContext ctx) =>
      _nunito(30 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w800, AppColors.textPrimary);

  // Subtitle under login headline
  static TextStyle loginSubtitle(BuildContext ctx) =>
      _nunito(18 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w500, AppColors.textSecondary);

  // Large initial letter inside profile card avatar circle
  static TextStyle avatarInitial(BuildContext ctx, Color color) =>
      _nunito(34 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w800, color);

  // Profile card name (e.g. "Pqr")
  static TextStyle profileCardName(BuildContext ctx) =>
      _nunito(24 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w800, AppColors.textPrimary);

  // Profile card role label (e.g. "Patient")
  static TextStyle profileCardRole(BuildContext ctx, Color color) =>
      _nunito(15 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w600, color);

  // PIN pad "Hi Name!" prompt
  static TextStyle pinGreeting(BuildContext ctx) =>
      _nunito(22 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w800, AppColors.textPrimary);

  // PIN pad subtitle
  static TextStyle pinSubtitle(BuildContext ctx) =>
      _nunito(17 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w400, AppColors.textSecondary);

  // PIN pad number keys
  static TextStyle pinKey(BuildContext ctx) =>
      _nunito(28 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w700, AppColors.textPrimary);

  // PIN pad backspace key
  static TextStyle pinBackspace(BuildContext ctx) =>
      _nunito(24 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w700, AppColors.textSecondary);

  // Footer note at bottom of login screen
  static TextStyle footerNote(BuildContext ctx) =>
      _nunito(13 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w400, AppColors.textHint);
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.scaffoldBg,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBg,

      // Card
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // Elevated button — large, full-width by default
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          textStyle: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(48, 48),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        labelStyle: GoogleFonts.nunito(fontSize: 18, color: AppColors.textSecondary),
        hintStyle: GoogleFonts.nunito(fontSize: 18, color: AppColors.textHint),
      ),

      // Chip
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 28),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBg,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cardBg,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
