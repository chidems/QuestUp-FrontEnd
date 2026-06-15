import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../models/history_models.dart';
import '../providers/history_provider.dart';

class QuestHistoryScreen extends ConsumerWidget {
  const QuestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quest History')),
      body: history.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load your history.',
          onRetry: () => ref.invalidate(historyProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              message: 'No completed quests yet.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(historyProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _HistoryRow(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final QuestHistoryItem item;
  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          item.photoUrl != null && item.photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: AppRadius.rSmall,
                  child: CachedNetworkImage(
                    imageUrl: item.photoUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : CategoryIcon(questType: item.questType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (item.completedAt != null)
                  Text(
                    _formatDate(item.completedAt!),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: context.colors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 14, color: context.colors.xpColor),
                  const SizedBox(width: 2),
                  Text('${item.xpEarned}',
                      style: TextStyle(
                          color: context.colors.xpColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.monetization_on,
                      size: 14, color: context.colors.accent),
                  const SizedBox(width: 2),
                  Text('${item.coinsEarned}',
                      style: TextStyle(
                          color: context.colors.accent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
