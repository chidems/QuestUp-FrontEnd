import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/achievements_provider.dart';
import 'achievement_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: achievements.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load achievements.',
          onRetry: () => ref.invalidate(achievementsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.military_tech,
              message: 'No achievements yet. Start completing quests!',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(achievementsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => AchievementCard(achievement: items[i]),
            ),
          );
        },
      ),
    );
  }
}
