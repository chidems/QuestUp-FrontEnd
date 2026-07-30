import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/weekly_quest_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../quests/providers/quest_feed_provider.dart';
import '../models/weekly_models.dart';
import '../providers/weekly_provider.dart';

class WeeklyQuestScreen extends ConsumerWidget {
  const WeeklyQuestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyProvider);
    // This screen shows the *community* weekly quest, whose id belongs to
    // /community/weekly/* and 404s on /quests/{id}. The player's own instance
    // of that quest comes from the feed — that's the one the quest screen can
    // load and complete.
    final userQuestId = ref.watch(questFeedProvider).value?.weeklyQuest?.id;
    final currentUserId = ref.watch(authStateProvider).value?.id;

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
          child: _Body(
            data: data,
            userQuestId: userQuestId,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final WeeklyData data;
  final String? userQuestId;
  final String? currentUserId;
  const _Body({
    required this.data,
    required this.userQuestId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final status = data.status;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (status == null)
          const _NoActiveQuest()
        else
          WeeklyQuestCard(
            quest: status.quest,
            isCompleted: status.isCompleted,
            onTap: userQuestId == null
                ? null
                : () => context.push('/quests/$userQuestId'),
          ),
        if (status != null) ...[
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
                child: _PhotoCard(
                  post: p,
                  isOwnPost: currentUserId != null && p.userId == currentUserId,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _NoActiveQuest extends StatelessWidget {
  const _NoActiveQuest();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, size: 40, color: context.colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No weekly quest right now.\nCheck back soon!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
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
  final bool isOwnPost;
  const _PhotoCard({required this.post, required this.isOwnPost});

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
          AspectRatio(aspectRatio: 3 / 2, child: _PhotoImage(post: post)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No like button here yet: liking isn't wired up on the
                // backend (no endpoint, no per-user like tracking — see
                // BACKEND_CHANGES_COMMUNITY_LIKES.md), so showing a heart
                // players could tap for nothing would just read as broken.
                Text(
                  isOwnPost ? 'You' : post.userDisplayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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

/// The photo for one community post. The backend's photo flow is
/// mock/local-only for now (see BACKEND_CHANGES_COMMUNITY_PHOTOS.md):
/// [WeeklyPhotoPost.photoUrl] is a local:// placeholder with nothing hosted
/// behind it, not a real image any device could fetch. For the device that
/// made the post, [localPhotoPathProvider] resolves the real file it was
/// shared from, so that one device can still see its own photo; everyone
/// else sees an honest "pending" placeholder instead of a broken-image icon.
class _PhotoImage extends ConsumerWidget {
  final WeeklyPhotoPost post;
  const _PhotoImage({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (post.photoUrl.startsWith('http')) {
      return CachedNetworkImage(
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
      );
    }

    final localPath = ref.watch(localPhotoPathProvider(post.id)).value;
    if (localPath != null) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }

    return ColoredBox(
      color: context.colors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_back, color: context.colors.textMuted),
          const SizedBox(height: 6),
          Text(
            'Photo pending upload support',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}
