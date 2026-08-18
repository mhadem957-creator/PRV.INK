import 'package:flutter/material.dart';

/// INK design system — Manga / Inked (Neubrutalism) aesthetics.
///
/// Paper background, thick ink borders, hard offset shadows, and crimson accents.
/// Supports light, dark, and system-driven themes.
class MangaTheme {
  MangaTheme._();

  // ── Light palette ────────────────────────────────────────────────────────
  static const Color paper = Color(0xFFF6F5F0);
  static const Color ink = Color(0xFF121212);
  static const Color crimson = Color(0xFFE60012);
  static const Color paperDark = Color(0xFFE8E6DF);
  static const Color inkLight = Color(0xFF2A2A2A);

  // ── Dark palette (inked night) ───────────────────────────────────────────
  static const Color nightPaper = Color(0xFF161614);
  static const Color nightPaperMuted = Color(0xFF242420);
  static const Color nightInk = Color(0xFFF0EDE6);
  static const Color nightInkDim = Color(0xFFB8B5AE);

  // ── Borders & Shadows ────────────────────────────────────────────────────
  static const double borderWidth = 3.0;
  static const double borderWidthThick = 4.0;
  static const Offset shadowOffset = Offset(4, 4);
  static const Offset shadowOffsetHeavy = Offset(5, 5);

  // ── Context-aware colors ─────────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color paperOf(BuildContext context) =>
      isDark(context) ? nightPaper : paper;

  static Color paperMutedOf(BuildContext context) =>
      isDark(context) ? nightPaperMuted : paperDark;

  static Color inkOf(BuildContext context) =>
      isDark(context) ? nightInk : ink;

  static Color inkDimOf(BuildContext context) =>
      isDark(context) ? nightInkDim : ink.withOpacity(0.65);

  static Color onAccentOf(BuildContext context) =>
      isDark(context) ? nightPaper : paper;

  static BoxShadow hardShadowOf(BuildContext context) => BoxShadow(
        color: inkOf(context),
        offset: shadowOffset,
        blurRadius: 0,
        spreadRadius: 0,
      );

  static BoxShadow hardShadowHeavyOf(BuildContext context) => BoxShadow(
        color: inkOf(context),
        offset: shadowOffsetHeavy,
        blurRadius: 0,
        spreadRadius: 0,
      );

  static Border thickBorderOf(BuildContext context) =>
      Border.all(color: inkOf(context), width: borderWidth);

  // Legacy static getters (light-mode defaults; prefer *Of(context) in UI)
  static BoxShadow get hardShadow => const BoxShadow(
        color: ink,
        offset: shadowOffset,
        blurRadius: 0,
        spreadRadius: 0,
      );

  static BoxShadow get hardShadowHeavy => const BoxShadow(
        color: ink,
        offset: shadowOffsetHeavy,
        blurRadius: 0,
        spreadRadius: 0,
      );

  static Border get thickBorder => Border.all(color: ink, width: borderWidth);

  static Border get thickBorderHeavy =>
      Border.all(color: ink, width: borderWidthThick);

  // ── ThemeData builders ───────────────────────────────────────────────────
  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: paper,
        bgMuted: paperDark,
        fg: ink,
        fgDim: inkLight,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: nightPaper,
        bgMuted: nightPaperMuted,
        fg: nightInk,
        fgDim: nightInkDim,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color bgMuted,
    required Color fg,
    required Color fgDim,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: crimson,
        onPrimary: brightness == Brightness.dark ? nightPaper : paper,
        secondary: fg,
        onSecondary: bg,
        surface: bg,
        onSurface: fg,
        error: crimson,
        onError: brightness == Brightness.dark ? nightPaper : paper,
        outline: fg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: fg, size: 24),
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: bg,
        elevation: 0,
        height: 64,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimson,
          foregroundColor:
              brightness == Brightness.dark ? nightPaper : paper,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: fg, width: 2.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: fg, width: 2.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: fg,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fg, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fg, width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: crimson, width: 3),
        ),
        labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: fgDim),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: fg, width: 4),
        ),
        titleTextStyle: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1,
        ),
        contentTextStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: fg,
        contentTextStyle: TextStyle(
          color: bg,
          fontWeight: FontWeight.w700,
        ),
        actionTextColor: crimson,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: crimson,
        linearTrackColor: bgMuted,
      ),
      dividerTheme: DividerThemeData(
        color: fg,
        thickness: 2,
        space: 1,
      ),
      iconTheme: IconThemeData(color: fg, size: 24),
      textTheme: base.textTheme
          .apply(bodyColor: fg, displayColor: fg)
          .copyWith(
            titleLarge: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: fg,
            ),
            titleMedium: TextStyle(
              fontWeight: FontWeight.w800,
              color: fg,
            ),
            bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: fg),
            bodyMedium: TextStyle(color: fg),
            labelLarge: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
      cardTheme: CardTheme(
        color: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: fg, width: borderWidth),
        ),
        margin: const EdgeInsets.all(8),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: fg,
        textColor: fg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return crimson;
          return fg;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return crimson.withOpacity(0.35);
          }
          return bgMuted;
        }),
        trackOutlineColor: MaterialStateProperty.all(fg),
        trackOutlineWidth: MaterialStateProperty.all(2),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return crimson;
          return bg;
        }),
        checkColor: MaterialStateProperty.all(
          brightness == Brightness.dark ? nightPaper : paper,
        ),
        side: BorderSide(color: fg, width: 2.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: fg, width: 2),
        ),
      ),
    );
  }
}
