import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../models/quest_models.dart';
import '../providers/quest_detail_provider.dart';

class QuestDetailScreen extends ConsumerWidget {
  final String questId;

  const QuestDetailScreen({super.key, required this.questId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quest = ref.watch(questDetailProvider(questId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quest')),
      body: quest.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load this quest.',
          onRetry: () => ref.invalidate(questDetailProvider(questId)),
        ),
        data: (q) => _QuestDetailBody(quest: q),
      ),
    );
  }
}

class _QuestDetailBody extends StatelessWidget {
  final Quest quest;
  const _QuestDetailBody({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CategoryIcon(questType: quest.questType, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      quest.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoTile(
                    icon: Icons.star,
                    label: 'Difficulty',
                    value: quest.difficultyLabel,
                  ),
                  _InfoTile(
                    icon: Icons.bolt,
                    label: 'XP',
                    value: '${quest.xpReward}',
                    color: AppColors.xpColor,
                  ),
                  _InfoTile(
                    icon: Icons.monetization_on,
                    label: 'Coins',
                    value: '${quest.coinReward}',
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Description',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                quest.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (quest.targetPlaceName != null ||
                  quest.targetLatitude != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Location',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _LocationInfo(quest: quest),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: PixelButton(
                label: 'Complete Quest',
                onPressed: () => context.push('/quests/${quest.id}/complete'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final Quest quest;
  const _LocationInfo({required this.quest});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (quest.targetPlaceName != null) quest.targetPlaceName!,
      if (quest.distanceMeters != null)
        quest.distanceMeters! < 1000
            ? '${quest.distanceMeters!.round()} m away'
            : '${(quest.distanceMeters! / 1000).toStringAsFixed(1)} km away',
      if (quest.targetLatitude != null && quest.targetLongitude != null)
        '${quest.targetLatitude!.toStringAsFixed(4)}, '
            '${quest.targetLongitude!.toStringAsFixed(4)}',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.place, size: 18, color: AppColors.locationQuest),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lines.join('\n'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: c, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
