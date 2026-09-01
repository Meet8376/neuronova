import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
// Original NeuroNova Palette: Warm Teal + Saffron + Soft Off-White

class AppColors {
  AppColors._();

  // Primary — a warm teal that feels calm and trustworthy, not cold/clinical
  static const Color primary      = Color(0xFF2A7B6F);
  static const Color primaryLight = Color(0xFF4CA99A);
  static const Color primaryDark  = Color(0xFF1A5C53);

  // Accent — warm saffron, culturally familiar for Indian users
  static const Color accent       = Color(0xFFE8A020);
  static const Color accentLight  = Color(0xFFF5C45E);

  // Emergency / SOS
  static const Color emergency      = Color(0xFFD93025);
  static const Color emergencyLight = Color(0xFFFF6B6B);

  // Backgrounds — warm off-white, soft on aging eyes
  static const Color scaffoldBg   = Color(0xFFF5F2EE);
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color cardBgWarm   = Color(0xFFFDF8F2);

  // Text — near-black, never pure #000000
  static const Color textPrimary   = Color(0xFF1C1C2E);
  static const Color textSecondary = Color(0xFF5A5A72);
  static const Color textHint      = Color(0xFF9A9AB0);

  // Status colours — always paired with icon/text
  static const Color success = Color(0xFF2E7D5A); // done
  static const Color warning = Color(0xFFD4760A); // in-progress / snooze
  static const Color error   = Color(0xFFC0392B); // missed / alert
  static const Color info    = Color(0xFF2A5C8A); // upcoming

  // Surface shades
  static const Color divider        = Color(0xFFE0DDD8);
  static const Color surfaceVariant = Color(0xFFEFEBE6);

  // Nav
  static const Color navSelected   = primary;
  static const Color navUnselected = Color(0xFFA0A0B8);

  // TTS highlight
  static const Color wordHighlight     = Color(0xFFFFE082);
  static const Color wordHighlightText = Color(0xFF1C1C2E);

  static const Color cardBorder = Color(0xFFE0DDD8);

  // Gradient stops for the header hero
  static const List<Color> heroGradient = [
    Color(0xFF2A7B6F),
    Color(0xFF4CA99A),
    Color(0xFFE8A020),
  ];
}

// ─── Gradient helpers ─────────────────────────────────────────────────────────

class AppGradients {
  AppGradients._();

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A5C53), Color(0xFF2A7B6F), Color(0xFF3D9B8D)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient accentWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A020), Color(0xFFF5C45E)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
  );

  static LinearGradient card(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
  );
}

// ─── Shadows ──────────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get hero => [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get nav => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, -3),
    ),
  ];

  static List<BoxShadow> emergency = [
    BoxShadow(
      color: AppColors.emergency.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─── Typography ───────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _nunito(double size, FontWeight weight, Color color,
          {double height = 1.4}) =>
      GoogleFonts.nunito(
          fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle greeting(BuildContext ctx) => _nunito(
      26 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w800,
      Colors.white);

  static TextStyle greetingOnDark(BuildContext ctx) => _nunito(
      26 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w800,
      Colors.white);

  static TextStyle dateText(BuildContext ctx) => _nunito(
      14 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w500,
      Colors.white.withValues(alpha: 0.9));

  static TextStyle sectionHeader(BuildContext ctx) => _nunito(
      19 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w700,
      AppColors.textPrimary);

  static TextStyle cardTitle(BuildContext ctx) => _nunito(
      18 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w600,
      AppColors.textPrimary);

  static TextStyle cardSubtitle(BuildContext ctx) => _nunito(
      15 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w400,
      AppColors.textSecondary);

  static TextStyle gameText(BuildContext ctx) => _nunito(
      22 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w400,
      AppColors.textPrimary);

  static TextStyle transcriptText(BuildContext ctx) => _nunito(
      18 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w400,
      AppColors.textSecondary);

  static TextStyle body(BuildContext ctx) => _nunito(
      18 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w400,
      AppColors.textPrimary);

  static TextStyle button(BuildContext ctx) => _nunito(
      18 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w700, Colors.white);

  static TextStyle scoreLarge(BuildContext ctx) => _nunito(
      56 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w800,
      AppColors.textPrimary);

  static TextStyle badge(BuildContext ctx) => _nunito(
      13 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w600, Colors.white);

  static TextStyle label(BuildContext ctx) => _nunito(
      14 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w400,
      AppColors.textHint);

  static TextStyle appTitle(BuildContext ctx) => _nunito(
      26 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w800,
      AppColors.textPrimary);

  static TextStyle appTagline(BuildContext ctx) => _nunito(
      14 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w500,
      AppColors.textSecondary);

  static TextStyle loginHeadline(BuildContext ctx) => _nunito(
      28 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w800,
      AppColors.textPrimary);

  static TextStyle loginSubtitle(BuildContext ctx) => _nunito(
      16 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w500,
      AppColors.textSecondary);

  static TextStyle avatarInitial(BuildContext ctx, Color color) => _nunito(
      32 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w800, color);

  static TextStyle profileCardName(BuildContext ctx) => _nunito(
      22 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w800,
      AppColors.textPrimary);

  static TextStyle profileCardRole(BuildContext ctx, Color color) => _nunito(
      14 * MediaQuery.textScalerOf(ctx).scale(1), FontWeight.w600, color);

  static TextStyle pinGreeting(BuildContext ctx) => _nunito(
      22 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w800,
      AppColors.textPrimary);

  static TextStyle pinSubtitle(BuildContext ctx) => _nunito(
      16 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w400,
      AppColors.textSecondary);

  static TextStyle pinKey(BuildContext ctx) => _nunito(
      26 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w700,
      AppColors.textPrimary);

  static TextStyle pinBackspace(BuildContext ctx) => _nunito(
      22 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w700,
      AppColors.textSecondary);

  static TextStyle footerNote(BuildContext ctx) => _nunito(
      12 * MediaQuery.textScalerOf(ctx).scale(1),
      FontWeight.w400,
      AppColors.textHint);
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

      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          textStyle:
              GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          textStyle:
              GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
          minimumSize: const Size(48, 44),
        ),
      ),

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle:
            GoogleFonts.nunito(fontSize: 16, color: AppColors.textSecondary),
        hintStyle:
            GoogleFonts.nunito(fontSize: 16, color: AppColors.textHint),
      ),

      chipTheme: ChipThemeData(
        labelStyle:
            GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme:
            const IconThemeData(color: AppColors.textPrimary, size: 26),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBg,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        selectedLabelStyle:
            GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cardBg,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
