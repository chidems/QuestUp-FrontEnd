import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../../../shared/widgets/rarity_badge.dart';
import '../models/avatar_models.dart';
import '../providers/avatar_provider.dart';
import 'avatar_preview.dart';

class AvatarScreen extends ConsumerWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(avatarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Shop',
            onPressed: () => context.push(RouteNames.store),
          ),
        ],
      ),
      body: data.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load your avatar.',
          onRetry: () => ref.read(avatarProvider.notifier).refresh(),
        ),
        data: (avatarData) => RefreshIndicator(
          onRefresh: () => ref.read(avatarProvider.notifier).refresh(),
          child: _Body(
            data: avatarData,
            onEquip: (id) => ref.read(avatarProvider.notifier).equip(id),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AvatarData data;
  final void Function(String itemId) onEquip;

  const _Body({required this.data, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<AvatarItem>>{};
    for (final item in data.inventory) {
      grouped.putIfAbsent(item.itemType, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AvatarPreview(avatar: data.avatar),
        ),
        const SizedBox(height: 24),
        Text(
          'INVENTORY',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (data.inventory.isEmpty)
          _EmptyInventory()
        else
          for (final type in ItemType.all)
            if (grouped[type] != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  ItemType.label(type),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ...grouped[type]!.map(
                (item) => _InventoryRow(item: item, onEquip: onEquip),
              ),
            ],
      ],
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final AvatarItem item;
  final void Function(String itemId) onEquip;

  const _InventoryRow({required this.item, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ItemThumbnail(
            imageUrl: item.imageUrl,
            itemType: item.itemType,
            size: 52,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                RarityBadge(rarity: item.rarity),
              ],
            ),
          ),
          const SizedBox(width: 8),
          item.isEquipped
              ? const _EquippedLabel()
              : OutlinedButton(
                  onPressed: () => onEquip(item.id),
                  child: const Text('Equip'),
                ),
        ],
      ),
    );
  }
}

class _EquippedLabel extends StatelessWidget {
  const _EquippedLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.xpColor.withValues(alpha: 0.2),
        border: Border.all(color: context.colors.xpColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14, color: context.colors.xpColor),
          const SizedBox(width: 4),
          Text(
            'Equipped',
            style: TextStyle(
              color: context.colors.xpColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 40, color: context.colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No items yet.\nVisit the shop to gear up!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
