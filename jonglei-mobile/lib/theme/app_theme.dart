import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Warm Parchment Design System — Jonglei Fish Hub ─────────────────────────
// Warm linen/parchment backgrounds — light theme, same as auth screens.
// Primary: deep teal #0AB5A3 · Secondary: burnt orange #C4631A
// Text: dark ink #1C1914 on warm parchment backgrounds
// Typography: DM Serif Display / Outfit / JetBrains Mono

class AppColors {
  // Backgrounds — warm parchment (light)
  static const Color bgDeep     = Color(0xFFE8E4DC); // slightly deeper parchment
  static const Color bgBase     = Color(0xFFF0EDE5); // main scaffold — warm linen
  static const Color bgElevated = Color(0xFFFAFAF8); // card surface — near-white
  static const Color bgGlass    = Color(0x0A000000); // subtle dark glass overlay

  // Borders — warm
  static const Color border     = Color(0xFFD0CBC3); // warm divider

  // Brand
  static const Color primary       = Color(0xFF0AB5A3); // deep teal
  static const Color primaryGlow   = Color(0x1F0AB5A3); // 12% teal glow
  static const Color secondary     = Color(0xFFC4631A); // burnt orange (login screen accent)
  static const Color secondaryGlow = Color(0x26C4631A); // 15% burnt orange glow

  // Text — dark ink palette
  static const Color textPrimary   = Color(0xFF1C1914); // near-black heading
  static const Color textSecondary = Color(0xFF4A4238); // medium warm brown
  static const Color textMuted     = Color(0xFF7A7065); // muted warm grey

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color danger  = Color(0xFFEF4444);
  static const Color warning = Color(0xFFC4631A);

  // Legacy aliases (kept for screens that still reference old names)
  static const Color onSurface        = textPrimary;
  static const Color onSurfaceVariant = textSecondary;
  static const Color onSurfaceFaint   = textMuted;
  static const Color surfaceLow       = bgBase;
  static const Color surface          = bgElevated;
  static const Color surfaceHigh      = bgElevated;
  static const Color surfaceHighest   = Color(0xFFE8E4DC); // shimmer highlight
  static const Color primaryLight     = Color(0x1F0AB5A3); // teal glow
  static const Color secondaryLight   = Color(0x26C4631A);
  static const Color info             = Color(0xFF0AB5A3);
  static const Color infoLight        = Color(0x1F0AB5A3);
  static const Color successLight     = Color(0x1F10B981);
  static const Color warningLight     = Color(0x26C4631A);
  static const Color dangerLight      = Color(0x26EF4444);
}

class AppTextStyles {
  // DM Serif Display — editorial authority, headings
  static TextStyle display(double size, {Color? color, double? letterSpacing}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: size,
        color: color ?? AppColors.textPrimary,
        letterSpacing: letterSpacing ?? -0.02 * size,
        height: 1.1,
      );

  // Outfit — clean modern UI text
  static TextStyle ui(double size,
          {FontWeight weight = FontWeight.w400,
          Color? color,
          double? letterSpacing,
          double? height}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        letterSpacing: letterSpacing,
        height: height,
      );

  // JetBrains Mono — prices, IDs, data, quantities
  static TextStyle data(double size,
          {FontWeight weight = FontWeight.w400,
          Color? color,
          double? letterSpacing}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        letterSpacing: letterSpacing,
      );

  // Label — uppercase metadata stamps
  static TextStyle label(double size,
          {Color? color, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textSecondary,
        letterSpacing: 0.05 * size,
      );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.bgElevated,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // dark icons on light bg
        ),
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: AppColors.primary,
          letterSpacing: -0.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgElevated,
        iconColor: AppColors.textMuted,
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.outfit(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgElevated,
        indicatorColor: AppColors.primaryGlow,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.primary : AppColors.textMuted,
            size: 22,
          );
        }),
      ),
      cardTheme: const CardThemeData(color: AppColors.bgElevated),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgElevated,
        selectedColor: AppColors.primaryGlow,
        labelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }
}

// ─── Reusable design tokens ──────────────────────────────────────────────────

class AppRadius {
  static const double sm   = 6;
  static const double md   = 10;
  static const double lg   = 14;
  static const double xl   = 18;
  static const double card = 16;
}

class AppSpacing {
  static const double xs      = 4;
  static const double sm      = 8;
  static const double md      = 12;
  static const double lg      = 16;
  static const double xl      = 24;
  static const double xxl     = 32;
  static const double section = 44;
}

// ─── Ambient background blobs ─────────────────────────────────────────────────
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Burnt-orange blob — top-right (subtle warmth on parchment)
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Teal blob — bottom-left
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  // ignore: library_private_types_in_public_api
  final _Status status;

  const StatusBadge.pending({super.key})
      : label = 'PENDING',
        status = _Status.pending;
  const StatusBadge.confirmed({super.key})
      : label = 'CONFIRMED',
        status = _Status.confirmed;
  const StatusBadge.inTransit({super.key})
      : label = 'IN TRANSIT',
        status = _Status.inTransit;
  const StatusBadge.cleared({super.key})
      : label = 'CLEARED',
        status = _Status.cleared;
  const StatusBadge.flagged({super.key})
      : label = 'FLAGGED',
        status = _Status.flagged;

  static StatusBadge fromString(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return const StatusBadge.pending();
      case 'CONFIRMED':
        return const StatusBadge.confirmed();
      case 'IN TRANSIT':
        return const StatusBadge.inTransit();
      case 'CLEARED':
        return const StatusBadge.cleared();
      default:
        return const StatusBadge.flagged();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case _Status.pending:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
      case _Status.confirmed:
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case _Status.inTransit:
        bg = AppColors.secondaryGlow;
        fg = AppColors.secondary;
        break;
      case _Status.cleared:
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case _Status.flagged:
        bg = AppColors.dangerLight;
        fg = AppColors.danger;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4)),
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

// ─── Glass stat card ──────────────────────────────────────────────────────────
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
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.3)],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card)),
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
                        style: AppTextStyles.label(10,
                            color: AppColors.textSecondary)),
                    const Spacer(),
                    if (icon != null)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon,
                            size: 15, color: accentColor),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(value,
                    style: AppTextStyles.data(30,
                        weight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
