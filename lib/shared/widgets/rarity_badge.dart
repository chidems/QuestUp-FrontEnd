import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/quest_constants.dart';

class RarityBadge extends StatelessWidget {
  final String rarity;

  const RarityBadge({super.key, required this.rarity});

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(rarity);
    final label = rarity.isEmpty
        ? rarity
        : '${rarity[0].toUpperCase()}${rarity.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

Color rarityColor(String rarity) {
  switch (rarity) {
    case Rarity.uncommon:
      return AppColors.rarityUncommon;
    case Rarity.rare:
      return AppColors.rarityRare;
    case Rarity.epic:
      return AppColors.rarityEpic;
    case Rarity.legendary:
      return AppColors.rarityLegendary;
    default:
      return AppColors.rarityCommon;
  }
}
