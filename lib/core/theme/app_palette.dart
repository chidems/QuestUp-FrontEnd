import 'package:flutter/material.dart';

/// Theme-aware color palette for the pixel-art RPG look (dark slate / light
/// parchment). Read it in widgets via `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceDeep;

  // Pixel borders (chunky offset-shadow technique)
  final Color border;
  final Color borderDeep;
  final Color borderDeeper;

  // Brand / accents
  final Color primary;
  final Color primaryLight;
  final Color accent; // gold / coins
  final Color accentTeal;
  final Color accentPurple;
  final Color xpColor; // teal-green / XP
  final Color error;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textBody;
  final Color textMuted;
  final Color buttonText;

  // Quest categories
  final Color locationQuest;
  final Color socialQuest;
  final Color actionQuest;

  // Rarity tiers
  final Color rarityCommon;
  final Color rarityUncommon;
  final Color rarityRare;
  final Color rarityEpic;
  final Color rarityLegendary;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceDeep,
    required this.border,
    required this.borderDeep,
    required this.borderDeeper,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.accentTeal,
    required this.accentPurple,
    required this.xpColor,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBody,
    required this.textMuted,
    required this.buttonText,
    required this.locationQuest,
    required this.socialQuest,
    required this.actionQuest,
    required this.rarityCommon,
    required this.rarityUncommon,
    required this.rarityRare,
    required this.rarityEpic,
    required this.rarityLegendary,
  });

  static const dark = AppPalette(
    // Deeper background with clearer value steps between surfaces; gold is
    // reserved for currency/rewards (accent), not general headings.
    background: Color(0xFF1E2138),
    surface: Color(0xFF2E3354),
    surfaceVariant: Color(0xFF383E66),
    surfaceDeep: Color(0xFF16182C),
    border: Color(0xFF454B7E),
    borderDeep: Color(0xFF131527),
    borderDeeper: Color(0xFF0C0E1E),
    primary: Color(0xFF9B7BD8),
    primaryLight: Color(0xFFC8A8F0),
    accent: Color(0xFFF0A830),
    accentTeal: Color(0xFF20D4BE),
    accentPurple: Color(0xFFC8A8F0),
    xpColor: Color(0xFF20D4BE),
    error: Color(0xFFD85050),
    textPrimary: Color(0xFFECE6F2),
    textSecondary: Color(0xFFB8BCE0),
    textBody: Color(0xFFB8BCE0),
    // ≥4.5:1 (WCAG AA) on surface and surfaceVariant.
    textMuted: Color(0xFFACB0D2),
    buttonText: Color(0xFFECE6F2),
    locationQuest: Color(0xFF4A90D9),
    socialQuest: Color(0xFFEC6FB0),
    actionQuest: Color(0xFFF0A830),
    rarityCommon: Color(0xFF9090B8),
    rarityUncommon: Color(0xFF5AB85A),
    rarityRare: Color(0xFF4A90D9),
    rarityEpic: Color(0xFFC8A8F0),
    rarityLegendary: Color(0xFFF0A830),
  );

  static const light = AppPalette(
    background: Color(0xFFF5EFE0),
    surface: Color(0xFFFDF6E3),
    surfaceVariant: Color(0xFFE8D8B8),
    surfaceDeep: Color(0xFFEDE3C8),
    border: Color(0xFFC8B89A),
    borderDeep: Color(0xFFA09070),
    borderDeeper: Color(0xFF806040),
    primary: Color(0xFF7050B8),
    primaryLight: Color(0xFF8A6AD0),
    accent: Color(0xFFB8651A),
    accentTeal: Color(0xFF1A8C7D),
    accentPurple: Color(0xFF7050B8),
    xpColor: Color(0xFF1A8C7D),
    error: Color(0xFFC03838),
    textPrimary: Color(0xFF5A3E1B),
    textSecondary: Color(0xFF7A6A4A),
    textBody: Color(0xFF7A6A4A),
    // ≥4.5:1 (WCAG AA) on surface and surfaceVariant.
    textMuted: Color(0xFF665B43),
    buttonText: Color(0xFFE8E4D8),
    locationQuest: Color(0xFF2E7FD4),
    socialQuest: Color(0xFFC03888),
    actionQuest: Color(0xFFB8651A),
    rarityCommon: Color(0xFF8A7A5A),
    rarityUncommon: Color(0xFF2E9E50),
    rarityRare: Color(0xFF2E7FD4),
    rarityEpic: Color(0xFF7050B8),
    rarityLegendary: Color(0xFFB8651A),
  );

  /// Soft drop shadow for rounded cards/panels — a subtle lift, not the old
  /// chunky pixel border.
  List<BoxShadow> softShadow() => [
        BoxShadow(
          color: borderDeeper.withValues(alpha: 0.45),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceVariant: c(surfaceVariant, other.surfaceVariant),
      surfaceDeep: c(surfaceDeep, other.surfaceDeep),
      border: c(border, other.border),
      borderDeep: c(borderDeep, other.borderDeep),
      borderDeeper: c(borderDeeper, other.borderDeeper),
      primary: c(primary, other.primary),
      primaryLight: c(primaryLight, other.primaryLight),
      accent: c(accent, other.accent),
      accentTeal: c(accentTeal, other.accentTeal),
      accentPurple: c(accentPurple, other.accentPurple),
      xpColor: c(xpColor, other.xpColor),
      error: c(error, other.error),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textBody: c(textBody, other.textBody),
      textMuted: c(textMuted, other.textMuted),
      buttonText: c(buttonText, other.buttonText),
      locationQuest: c(locationQuest, other.locationQuest),
      socialQuest: c(socialQuest, other.socialQuest),
      actionQuest: c(actionQuest, other.actionQuest),
      rarityCommon: c(rarityCommon, other.rarityCommon),
      rarityUncommon: c(rarityUncommon, other.rarityUncommon),
      rarityRare: c(rarityRare, other.rarityRare),
      rarityEpic: c(rarityEpic, other.rarityEpic),
      rarityLegendary: c(rarityLegendary, other.rarityLegendary),
    );
  }
}

extension PaletteX on BuildContext {
  /// The active pixel palette (dark slate or light parchment).
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
