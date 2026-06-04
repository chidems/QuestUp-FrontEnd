import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/location/location_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/auth_models.dart';
import '../../npc/models/npc_models.dart';
import '../../npc/providers/npc_encounter_provider.dart';
import '../../npc/presentation/npc_encounter_modal.dart';
import '../../npc/presentation/walking_status_banner.dart';
import '../models/quest_models.dart';
import '../providers/quest_feed_provider.dart';
import 'quest_card.dart';

class QuestFeedScreen extends ConsumerWidget {
  const QuestFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(questFeedProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    // Show the NPC encounter modal when the walking session triggers one.
    ref.listen<NPCEncounter?>(npcEncounterProvider, (prev, next) {
      if (next != null && prev == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => NpcEncounterModal(encounter: next),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Quests')),
      body: Column(
        children: [
          if (user != null) _QuestFeedHud(user: user),
          const WalkingStatusBanner(),
          Expanded(
            child: feed.when(
              loading: () => const Center(
                child: _Loading(message: 'Finding quests near you...'),
              ),
              error: (error, _) => _FeedError(
                error: error,
                onRetry: () => ref.read(questFeedProvider.notifier).refresh(),
                onOpenSettings: () =>
                    ref.read(locationServiceProvider).openSettings(),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () => ref.read(questFeedProvider.notifier).refresh(),
                child: _FeedBody(feed: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final String message;
  const _Loading({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _FeedBody extends StatelessWidget {
  final QuestFeed feed;
  const _FeedBody({required this.feed});

  @override
  Widget build(BuildContext context) {
    final normal = feed.normalQuests;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (feed.weeklyQuest != null) ...[
          _SectionHeader('Weekly Quest'),
          const SizedBox(height: 8),
          QuestCard(
            quest: feed.weeklyQuest!,
            featured: true,
            onTap: () => context.push('/quests/${feed.weeklyQuest!.id}'),
          ),
          const SizedBox(height: 24),
        ],
        _SectionHeader('Active Quests'),
        const SizedBox(height: 8),
        if (normal.isEmpty)
          const _EmptyQuests()
        else
          ...normal.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuestCard(
                quest: q,
                onTap: () => context.push('/quests/${q.id}'),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyQuests extends StatelessWidget {
  const _EmptyQuests();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.explore_off, size: 40, color: context.colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No active quests right now.\nPull down to refresh and find new ones.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Distinguishes location problems (with an actionable button) from generic
/// failures.
class _FeedError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const _FeedError({
    required this.error,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isLocation = error is LocationException;
    final canOpenSettings =
        error is LocationException && (error as LocationException).canOpenSettings;
    final message = error is LocationException
        ? (error as LocationException).message
        : 'We could not load your quests. Try refreshing or moving to '
            'another area.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocation ? Icons.location_off : Icons.error_outline,
              size: 48,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (canOpenSettings)
              ElevatedButton(
                onPressed: onOpenSettings,
                child: const Text('Open settings'),
              )
            else
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

/// Compact top HUD: avatar, level, XP bar, coins, streak.
class _QuestFeedHud extends StatelessWidget {
  final User user;
  const _QuestFeedHud({required this.user});

  @override
  Widget build(BuildContext context) {
    // Placeholder XP-to-next-level (100 XP/level) until the backend exposes
    // the real threshold.
    final progress = (user.totalXp % 100) / 100;

    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.primary,
            child: Text(
              'L${user.level}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: context.colors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(context.colors.xpColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HudChip(
            icon: Icons.monetization_on,
            label: '${user.coins}',
            color: context.colors.accent,
          ),
          const SizedBox(width: 8),
          _HudChip(
            icon: Icons.local_fire_department,
            label: '${user.currentStreak}',
            color: context.colors.actionQuest,
          ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HudChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
