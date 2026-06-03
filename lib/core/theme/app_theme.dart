import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: AppColors.textPrimary,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
          ),
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: AppColors.surfaceVariant),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          bodySmall: TextStyle(color: AppColors.textMuted),
        ),
      );
}
