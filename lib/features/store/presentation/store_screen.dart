import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/constants/quest_constants.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../avatar/models/avatar_models.dart';
import '../../avatar/providers/avatar_provider.dart';
import '../providers/store_provider.dart';
import 'item_card.dart';

const _rarities = [
  Rarity.common,
  Rarity.uncommon,
  Rarity.rare,
  Rarity.epic,
  Rarity.legendary,
];

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String? _rarity;

  Future<void> _buy(AvatarItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(storeProvider.notifier).buy(item.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Purchased ${item.name}!')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final coins = ref.watch(authStateProvider).value?.coins ?? 0;
    final appearance = ref.watch(appearanceProvider).value;
    final equippedIds = {appearance?.itemId};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.monetization_on,
                    color: context.colors.accent, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: TextStyle(
                    color: context.colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _RarityChips(
            rarity: _rarity,
            onSelect: (r) => setState(() => _rarity = r),
          ),
          Expanded(
            child: store.when(
              loading: () => const LoadingView(),
              error: (_, __) => ErrorView(
                message: 'Could not load the shop.',
                onRetry: () => ref.read(storeProvider.notifier).refresh(),
              ),
              data: (items) {
                final filtered = items
                    .where((i) => _rarity == null || i.rarity == _rarity)
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No items match the filter.'));
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(storeProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.80,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      var item = filtered[i];
                      if (equippedIds.contains(item.id)) {
                        item = item.copyWith(isEquipped: true);
                      }
                      return ItemCard(
                        item: item,
                        canAfford: coins >= item.priceCoins,
                        onBuy: () => _buy(item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityChips extends StatelessWidget {
  final String? rarity;
  final ValueChanged<String?> onSelect;

  const _RarityChips({required this.rarity, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final entry in [
            const MapEntry<String?, String>(null, 'All'),
            for (final r in _rarities) MapEntry<String?, String>(r, r),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Center(
                child: PixelChip(
                  label: entry.key == null
                      ? entry.value
                      : ItemType.label(entry.value),
                  selected: rarity == entry.key,
                  onTap: () => onSelect(entry.key),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
