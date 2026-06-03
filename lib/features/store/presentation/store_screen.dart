import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/quest_constants.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
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
  String? _type;
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

  Future<void> _equip(AvatarItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(avatarProvider.notifier).equip(item.id);
      ref.invalidate(storeProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Equipped ${item.name}.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not equip: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final coins = ref.watch(authStateProvider).valueOrNull?.coins ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    color: AppColors.accent,
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
          _Filters(
            type: _type,
            rarity: _rarity,
            onType: (t) => setState(() => _type = t),
            onRarity: (r) => setState(() => _rarity = r),
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
                    .where((i) =>
                        (_type == null || i.itemType == _type) &&
                        (_rarity == null || i.rarity == _rarity))
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
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return ItemCard(
                        item: item,
                        canAfford: coins >= item.priceCoins,
                        onBuy: () => _buy(item),
                        onEquip: () => _equip(item),
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

class _Filters extends StatelessWidget {
  final String? type;
  final String? rarity;
  final ValueChanged<String?> onType;
  final ValueChanged<String?> onRarity;

  const _Filters({
    required this.type,
    required this.rarity,
    required this.onType,
    required this.onRarity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChipRow(
          values: ItemType.all,
          selected: type,
          onSelect: onType,
        ),
        _ChipRow(
          values: _rarities,
          selected: rarity,
          onSelect: onRarity,
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _ChipRow({
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(context, label: 'All', value: null),
          for (final v in values)
            _chip(context, label: ItemType.label(v), value: v),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String label, required String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onSelect(value),
      ),
    );
  }
}
