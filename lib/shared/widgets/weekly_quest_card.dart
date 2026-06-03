import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/quests/models/quest_models.dart';
import 'category_icon.dart';

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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  'THIS WEEK',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                ),
                const Spacer(),
                if (isCompleted) const _CompletedBadge(),
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
                            color: AppColors.xpColor,
                          ),
                          const SizedBox(width: 12),
                          _Reward(
                            icon: Icons.monetization_on,
                            label: '${quest.coinReward}',
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.xpColor.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.xpColor),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14, color: AppColors.xpColor),
          SizedBox(width: 4),
          Text(
            'Completed',
            style: TextStyle(
              color: AppColors.xpColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
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
