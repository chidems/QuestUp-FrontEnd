import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/achievement_models.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final color = unlocked ? AppColors.accent : AppColors.textMuted;

    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: unlocked ? color : AppColors.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  unlocked ? Icons.military_tech : Icons.lock_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    achievement.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!unlocked) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: achievement.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(achievement.progress * 100).round()}%',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
