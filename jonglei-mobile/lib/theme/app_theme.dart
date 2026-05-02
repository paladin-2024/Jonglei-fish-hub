import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── The Resilient Ledger — Design System ───────────────────────────────────
// Palette rooted in Jonglei landscape: deep river teal + sun-baked amber.
// No pure black. No 1px dividers. Elevation via tonal layering only.

class AppColors {
  // Primary — deep teal of the White Nile
  static const primary = Color(0xFF005440);
  static const primaryLight = Color(0xFF0F6E56);
  static const onPrimary = Colors.white;

  // Secondary — amber, the "ink stamp" of approval/action
  static const secondary = Color(0xFFB45309);
  static const secondaryLight = Color(0xFFFFDCBB);
  static const onSecondary = Color(0xFF1B1C1A);

  // Surface hierarchy — no borders, only tonal shift
  static const surface = Color(0xFFFFFFFF);         // Cards, input bg
  static const surfaceLow = Color(0xFFF4F4F0);      // Main canvas / background
  static const surfaceHigh = Color(0xFFE9E8E4);     // Navigation panels
  static const surfaceHighest = Color(0xFFE3E2DF);  // Sticky headers, active states

  // Text — never pure black
  static const onSurface = Color(0xFF1B1C1A);        // Primary text
  static const onSurfaceVariant = Color(0xFF3F4944); // Secondary / muted text
  static const onSurfaceFaint = Color(0xFF7A8C87);   // Placeholder, hint

  // Status
  static const success = Color(0xFF1A6B3C);
  static const successLight = Color(0xFFD6EFE1);
  static const warning = Color(0xFFB45309);
  static const warningLight = Color(0xFFFFDCBB);
  static const danger = Color(0xFFB91C1C);
  static const dangerLight = Color(0xFFFFE4E4);
  static const info = Color(0xFF1E5C8A);
  static const infoLight = Color(0xFFD6EAF8);
}

class AppTextStyles {
  // DM Serif Display — editorial authority, ledger-grade headings
  static TextStyle display(double size, {Color? color, double? letterSpacing}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: size,
        color: color ?? AppColors.onSurface,
        letterSpacing: letterSpacing ?? -0.02 * size,
        height: 1.1,
      );

  // Outfit — clean geometric UI text
  static TextStyle ui(double size,
          {FontWeight weight = FontWeight.w400,
          Color? color,
          double? letterSpacing,
          double? height}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurface,
        letterSpacing: letterSpacing,
        height: height,
      );

  // JetBrains Mono — all prices, IDs, quantities, codes
  static TextStyle data(double size,
          {FontWeight weight = FontWeight.w400,
          Color? color,
          double? letterSpacing}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurface,
        letterSpacing: letterSpacing,
      );

  // Label style — uppercase metadata stamps
  static TextStyle label(double size,
          {Color? color, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurfaceVariant,
        letterSpacing: 0.05 * size,
      );
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryLight,
        onSecondaryContainer: AppColors.onSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerLow: AppColors.surfaceLow,
        surfaceContainerHigh: AppColors.surfaceHigh,
        surfaceContainerHighest: AppColors.surfaceHighest,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLow,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLow,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.outfit(
          color: AppColors.onSurfaceFaint,
          fontSize: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 22,
          );
        }),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.secondaryLight,
        labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
    );
  }
}

// ─── Reusable design tokens ──────────────────────────────────────────────────

class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double card = 12;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 44; // Between major modules
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  // ignore: library_private_types_in_public_api
  final _Status status;

  const StatusBadge.pending({super.key}) : label = 'PENDING', status = _Status.pending;
  const StatusBadge.confirmed({super.key}) : label = 'CONFIRMED', status = _Status.confirmed;
  const StatusBadge.inTransit({super.key}) : label = 'IN TRANSIT', status = _Status.inTransit;
  const StatusBadge.cleared({super.key}) : label = 'CLEARED', status = _Status.cleared;
  const StatusBadge.flagged({super.key}) : label = 'FLAGGED', status = _Status.flagged;

  static StatusBadge fromString(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING': return const StatusBadge.pending();
      case 'CONFIRMED': return const StatusBadge.confirmed();
      case 'IN TRANSIT': return const StatusBadge.inTransit();
      case 'CLEARED': return const StatusBadge.cleared();
      default: return const StatusBadge.flagged();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case _Status.pending:   bg = AppColors.warningLight; fg = AppColors.warning; break;
      case _Status.confirmed: bg = AppColors.successLight; fg = AppColors.success; break;
      case _Status.inTransit: bg = AppColors.infoLight;    fg = AppColors.info;    break;
      case _Status.cleared:   bg = AppColors.successLight; fg = AppColors.success; break;
      case _Status.flagged:   bg = AppColors.dangerLight;  fg = AppColors.danger;  break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

enum _Status { pending, confirmed, inTransit, cleared, flagged }

// ─── Top-accent stat card (category color as TOP bar, not side-stripe) ───────
class LedgerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final IconData? icon;
  final bool wide;

  const LedgerStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    this.icon,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar — category indicator (top, not side — per impeccable)
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label.toUpperCase(),
                        style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant)),
                    const Spacer(),
                    if (icon != null)
                      Icon(icon, size: 16, color: accentColor.withValues(alpha: 0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(value, style: AppTextStyles.data(28, weight: FontWeight.w600, color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
