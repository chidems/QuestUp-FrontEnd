import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../../shared/widgets/rarity_badge.dart';
import '../../avatar/models/avatar_models.dart';

class ItemCard extends StatelessWidget {
  final AvatarItem item;
  final bool canAfford;
  final VoidCallback onBuy;

  const ItemCard({
    super.key,
    required this.item,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      padding: const EdgeInsets.all(10),
      highlightColor: item.isEquipped ? context.colors.xpColor : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inset backdrop plate so the art reads as a sprite slot.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.colors.surfaceDeep,
              borderRadius: AppRadius.rSmall,
            ),
            child: Center(
              child: ItemThumbnail(
                imageUrl: item.imageUrl,
                asset: item.asset,
                itemType: item.itemType,
                size: 56,
              ),
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
          RarityBadge(rarity: item.rarity),
          // Pin the action to the card bottom — no stranded whitespace.
          const Spacer(),
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
      // Equipping happens on the Hero screen's Items tab (left/right hand).
      return _StateButton(label: 'Owned', color: context.colors.primaryLight);
    }
    return PixelButton(
      label: '${item.priceCoins}',
      icon: Icons.monetization_on,
      fullWidth: true,
      color: context.colors.accent,
      textColor: Colors.black,
      onPressed: canAfford ? onBuy : null,
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
        borderRadius: AppRadius.rButton,
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
