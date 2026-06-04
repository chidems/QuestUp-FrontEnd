import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/weekly_quest_card.dart';
import '../models/weekly_models.dart';
import '../providers/weekly_provider.dart';

class WeeklyQuestScreen extends ConsumerWidget {
  const WeeklyQuestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Quest')),
      body: weekly.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load the weekly quest.',
          onRetry: () => ref.read(weeklyProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(weeklyProvider.notifier).refresh(),
          child: _Body(data: data),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final WeeklyData data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context) {
    final quest = data.status.quest;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WeeklyQuestCard(
          quest: quest,
          isCompleted: data.status.isCompleted,
          onTap: () => context.push('/quests/${quest.id}'),
        ),
        const SizedBox(height: 24),
        Text(
          'COMMUNITY PHOTOS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (data.photos.isEmpty)
          _EmptyPhotos()
        else
          ...data.photos.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PhotoCard(post: p),
            ),
          ),
      ],
    );
  }
}

class _EmptyPhotos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.photo_camera_back,
              size: 40, color: context.colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No shared photos yet.\nComplete the quest and be the first!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final WeeklyPhotoPost post;
  const _PhotoCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.primaryLight),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: CachedNetworkImage(
              imageUrl: post.photoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => ColoredBox(
                color: context.colors.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => ColoredBox(
                color: context.colors.surfaceVariant,
                child: Icon(Icons.broken_image, color: context.colors.textMuted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.userDisplayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (post.likesCount != null) ...[
                      Icon(Icons.favorite,
                          size: 14, color: context.colors.socialQuest),
                      const SizedBox(width: 3),
                      Text('${post.likesCount}',
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ],
                ),
                if (post.caption != null && post.caption!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(post.caption!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (post.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(post.createdAt!),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: context.colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
