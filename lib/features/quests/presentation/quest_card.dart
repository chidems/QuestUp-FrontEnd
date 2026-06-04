import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../models/quest_models.dart';

/// RPG-style mission card. Set [featured] for the weekly quest highlight.
class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onTap;
  final bool featured;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return PixelBox(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: featured ? p.surfaceVariant : p.surface,
      highlightColor: featured ? p.accent : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(questType: quest.questType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaChip(
                      icon: Icons.star,
                      label: quest.difficultyLabel,
                      color: p.textSecondary,
                    ),
                    if (quest.distanceMeters != null)
                      _MetaChip(
                        icon: Icons.near_me,
                        label: _distanceLabel(quest.distanceMeters!),
                        color: p.locationQuest,
                      ),
                    _MetaChip(
                      icon: Icons.bolt,
                      label: '${quest.xpReward} XP',
                      color: p.xpColor,
                    ),
                    _MetaChip(
                      icon: Icons.monetization_on,
                      label: '${quest.coinReward}',
                      color: p.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: p.textMuted),
        ],
      ),
    );
  }

  String _distanceLabel(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
