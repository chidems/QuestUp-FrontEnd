import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../../../shared/widgets/rarity_badge.dart';
import '../../avatar/models/avatar_models.dart';

class ItemCard extends StatelessWidget {
  final AvatarItem item;
  final bool canAfford;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  const ItemCard({
    super.key,
    required this.item,
    required this.canAfford,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      padding: const EdgeInsets.all(10),
      highlightColor: item.isEquipped ? context.colors.xpColor : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ItemThumbnail(
              imageUrl: item.imageUrl,
              itemType: item.itemType,
              size: 72,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  ItemType.label(item.itemType),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: context.colors.textMuted),
                ),
              ),
              RarityBadge(rarity: item.rarity),
            ],
          ),
          const SizedBox(height: 8),
          _action(context),
        ],
      ),
    );
  }

  Widget _action(BuildContext context) {
    if (item.isEquipped) {
      return _StateButton(label: 'Equipped', color: context.colors.xpColor);
    }
    if (item.isOwned) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: onEquip, child: const Text('Equip')),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canAfford ? onBuy : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.accent,
          foregroundColor: Colors.black,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on, size: 16),
            const SizedBox(width: 4),
            Text('${item.priceCoins}'),
          ],
        ),
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  final String label;
  final Color color;

  const _StateButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
