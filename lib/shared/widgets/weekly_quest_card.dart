import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../features/quests/models/quest_models.dart';
import 'category_icon.dart';
import 'pixel_badge.dart';
import 'pixel_box.dart';

/// Highlighted card for the shared weekly community quest, with a completion
/// status badge.
class WeeklyQuestCard extends StatelessWidget {
  final Quest quest;
  final bool isCompleted;
  final VoidCallback onTap;

  const WeeklyQuestCard({
    super.key,
    required this.quest,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return PixelBox(
      onTap: onTap,
      color: p.surfaceVariant,
      highlightColor: p.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: p.accent, size: 18),
              const SizedBox(width: 6),
              Text(
                'THIS WEEK',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: p.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
              ),
              const Spacer(),
              if (isCompleted)
                PixelBadge(
                  label: 'Completed',
                  color: p.xpColor,
                  icon: Icons.check,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
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
                    Row(
                      children: [
                        _Reward(
                            icon: Icons.bolt,
                            label: '${quest.xpReward} XP',
                            color: p.xpColor),
                        const SizedBox(width: 12),
                        _Reward(
                            icon: Icons.monetization_on,
                            label: '${quest.coinReward}',
                            color: p.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Reward({
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
