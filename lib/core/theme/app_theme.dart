import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  /// Pixel display font (Press Start 2P, bundled in assets/fonts): single
  /// case, single weight, runs wide — keep sizes small and line-height
  /// generous. Headings/HUD only; body text stays on the system font for
  /// readability.
  static TextStyle _px(double size, Color color, {double spacing = 0}) =>
      TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: size,
        color: color,
        letterSpacing: spacing,
        height: 1.5,
      );

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final onAccent = brightness == Brightness.dark ? Colors.black : Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.buttonText,
        secondary: p.accent,
        onSecondary: onAccent,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _px(14, p.textPrimary),
      ),
      // Soft rounded surfaces everywhere.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppRadius.rChip,
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rChip,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rChip,
          borderSide: BorderSide(color: p.primaryLight, width: 2),
        ),
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.buttonText,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rButton),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primaryLight,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rButton),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primaryLight),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rCard),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primaryLight,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontFamily: 'PressStart2P', fontSize: 8),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'PressStart2P', fontSize: 8),
      ),
      dividerTheme: DividerThemeData(color: p.border),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primaryLight),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceVariant,
        contentTextStyle: TextStyle(color: p.textPrimary),
      ),
      textTheme: TextTheme(
        // Pixel display font: screen titles, dialog headlines, section labels.
        displayLarge: _px(26, p.textPrimary, spacing: 1),
        headlineLarge: _px(20, p.textPrimary),
        headlineMedium: _px(16, p.textPrimary),
        headlineSmall: _px(13, p.textPrimary),
        titleLarge: _px(13, p.textPrimary),
        labelLarge: _px(10, p.textSecondary, spacing: 0.5),
        // System font: real content stays readable.
        titleMedium: TextStyle(
            color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: p.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: p.textBody, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: p.textMuted, fontSize: 12, height: 1.35),
        labelMedium: TextStyle(
            color: p.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: p.textMuted, fontSize: 11),
      ),
    );
  }
}
