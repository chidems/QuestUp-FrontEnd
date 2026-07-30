import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../models/quest_models.dart';
import '../providers/accepted_quests_provider.dart';
import '../providers/quest_detail_provider.dart';
import '../providers/quest_feed_provider.dart';

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
                    color: context.colors.xpColor,
                  ),
                  _InfoTile(
                    icon: Icons.monetization_on,
                    label: 'Coins',
                    value: '${quest.coinReward}',
                    color: context.colors.accent,
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
        _QuestActions(quest: quest),
      ],
    );
  }
}

/// Bottom action bar. A quest the player has not picked up yet can only be
/// accepted; once it is active it can be completed or abandoned.
class _QuestActions extends ConsumerStatefulWidget {
  final Quest quest;
  const _QuestActions({required this.quest});

  @override
  ConsumerState<_QuestActions> createState() => _QuestActionsState();
}

class _QuestActionsState extends ConsumerState<_QuestActions> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(acceptedQuestIdsProvider.notifier).accept(widget.quest.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Quest accepted! Find it in Active Quests.'),
        ),
      );
      // Land on the feed so the quest is visible in its new home.
      router.go(RouteNames.home);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not accept this quest: $e')),
      );
    }
  }

  Future<void> _abandon() async {
    // Abandoning skips the quest for good, so make that explicit first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Abandon this quest?'),
        content: const Text(
          "It won't come back, but a new quest will take its place.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref
          .read(acceptedQuestIdsProvider.notifier)
          .abandon(widget.quest.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Quest abandoned.')),
      );
      router.go(RouteNames.home);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not abandon this quest: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accepted =
        isQuestAccepted(widget.quest, ref.watch(acceptedQuestIdsProvider));
    // This screen's own fetch (GET /quests/{id}) and the feed's copy of the
    // weekly quest (POST /quests/session/open, watched by the Weekly tab) are
    // two separate calls against the same underlying record. Cross-check the
    // feed's copy too, so a completed weekly quest can't show "Complete
    // Quest" here just because this screen's own fetch lagged behind.
    final feedWeekly = widget.quest.isWeekly
        ? ref.watch(questFeedProvider).value?.weeklyQuest
        : null;
    final completed = widget.quest.status == 'completed' ||
        (feedWeekly != null &&
            feedWeekly.id == widget.quest.id &&
            feedWeekly.status == 'completed');
    final complete = PixelButton(
      label: 'Complete Quest',
      fullWidth: true,
      onPressed: () => context.push('/quests/${widget.quest.id}/complete'),
    );

    final Widget actions;
    if (completed) {
      // Otherwise a completed weekly quest — which stays in the feed for the
      // rest of the week rather than disappearing like a normal quest —
      // would keep offering "Complete Quest" every time it's reopened.
      actions = const PixelButton(
        label: 'Quest Completed',
        icon: Icons.check_circle,
        fullWidth: true,
        variant: PixelButtonVariant.neutral,
        onPressed: null,
      );
    } else if (!accepted) {
      actions = PixelButton(
        label: 'Accept Quest',
        fullWidth: true,
        isLoading: _busy,
        onPressed: _busy ? null : _accept,
      );
    } else if (widget.quest.isWeekly) {
      // The weekly quest is assigned for the week — completable, not droppable.
      actions = complete;
    } else {
      actions = Row(
        children: [
          Expanded(
            child: PixelButton(
              label: 'Abandon',
              fullWidth: true,
              variant: PixelButtonVariant.destructive,
              onPressed: _busy ? null : _abandon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: complete),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Padding(padding: const EdgeInsets.all(16), child: actions),
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
        Icon(Icons.place, size: 18, color: context.colors.locationQuest),
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
    final c = color ?? context.colors.textSecondary;
    return PixelBox(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
