import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/quest_constants.dart';
import '../../features/quests/models/completion_models.dart';

/// Shows the post-completion reward summary. Resolves when dismissed.
Future<void> showRewardSummary(
  BuildContext context,
  QuestCompletionResult result,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RewardSummaryModal(result: result),
  );
}

class RewardSummaryModal extends StatelessWidget {
  final QuestCompletionResult result;

  const RewardSummaryModal({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.accent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: AppColors.accent, size: 48),
            const SizedBox(height: 8),
            Text(
              'Quest Complete!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (result.message != null) ...[
              const SizedBox(height: 4),
              Text(
                result.message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardStat(
                  icon: Icons.bolt,
                  label: '+${result.xpGained} XP',
                  color: AppColors.xpColor,
                ),
                const SizedBox(width: 20),
                _RewardStat(
                  icon: Icons.monetization_on,
                  label: '+${result.coinsGained}',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 20),
                _RewardStat(
                  icon: Icons.local_fire_department,
                  label: '${result.streakCount}',
                  color: AppColors.actionQuest,
                ),
              ],
            ),
            if (result.didLevelUp) ...[
              const SizedBox(height: 16),
              _Banner(
                icon: Icons.arrow_upward,
                text: 'Level up! ${result.levelBefore} → ${result.levelAfter}',
                color: AppColors.primaryLight,
              ),
            ],
            if (result.statChanges.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: result.statChanges.entries
                    .map((e) => _Pill('+${e.value} ${_label(e.key)}'))
                    .toList(),
              ),
            ],
            for (final a in result.unlockedAchievements) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.military_tech,
                text: 'Achievement: ${a.name}',
                color: AppColors.xpColor,
              ),
            ],
            for (final item in result.itemRewards) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.card_giftcard,
                text: 'Item: ${item.name}',
                color: _rarityColor(item.rarity),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Awesome!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(String key) => key.isEmpty
      ? key
      : '${key[0].toUpperCase()}${key.substring(1)}';

  Color _rarityColor(String rarity) {
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
}

class _RewardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Banner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
