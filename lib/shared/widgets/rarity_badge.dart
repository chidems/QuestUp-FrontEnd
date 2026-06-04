import 'package:flutter/material.dart';
import '../../core/constants/quest_constants.dart';
import '../../core/theme/app_palette.dart';
import 'pixel_badge.dart';

class RarityBadge extends StatelessWidget {
  final String rarity;

  const RarityBadge({super.key, required this.rarity});

  @override
  Widget build(BuildContext context) {
    final label = rarity.isEmpty
        ? rarity
        : '${rarity[0].toUpperCase()}${rarity.substring(1)}';
    return PixelBadge(label: label, color: rarityColor(context.colors, rarity));
  }
}

Color rarityColor(AppPalette p, String rarity) {
  switch (rarity) {
    case Rarity.uncommon:
      return p.rarityUncommon;
    case Rarity.rare:
      return p.rarityRare;
    case Rarity.epic:
      return p.rarityEpic;
    case Rarity.legendary:
      return p.rarityLegendary;
    default:
      return p.rarityCommon;
  }
}
