import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

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
      ),
      // Pixel style: hard rectangular edges everywhere.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primaryLight,
          side: BorderSide(color: p.border),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primaryLight),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primaryLight,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(color: p.border),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primaryLight),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceVariant,
        contentTextStyle: TextStyle(color: p.textPrimary),
      ),
      textTheme: TextTheme(
        headlineLarge:
            TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium:
            TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold),
        headlineSmall:
            TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
        titleLarge:
            TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: p.textPrimary),
        titleSmall: TextStyle(color: p.textPrimary),
        bodyLarge: TextStyle(color: p.textPrimary),
        bodyMedium: TextStyle(color: p.textBody),
        bodySmall: TextStyle(color: p.textMuted),
        labelLarge: TextStyle(color: p.textSecondary),
        labelSmall: TextStyle(color: p.textMuted),
      ),
    );
  }
}
