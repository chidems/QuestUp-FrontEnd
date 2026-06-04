import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../models/avatar_models.dart';

/// Renders the equipped look. Layers item images back-to-front when assets are
/// available; otherwise shows a placeholder until pixel-art assets are added.
class AvatarPreview extends StatelessWidget {
  final Avatar avatar;

  const AvatarPreview({super.key, required this.avatar});

  @override
  Widget build(BuildContext context) {
    final layers = [
      for (final type in ItemType.layerOrder)
        ...avatar.equipped.where(
          (i) => i.itemType == type && (i.imageUrl?.isNotEmpty ?? false),
        ),
    ];

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: context.colors.pixelBorder(),
        ),
        clipBehavior: Clip.hardEdge,
        child: layers.isEmpty
            ? _Placeholder(equippedCount: avatar.equipped.length)
            : Stack(
                fit: StackFit.expand,
                children: [
                  for (final item in layers)
                    CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final int equippedCount;
  const _Placeholder({required this.equippedCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 80, color: context.colors.primaryLight),
          const SizedBox(height: 8),
          Text(
            equippedCount == 0
                ? 'Equip items to customize'
                : '$equippedCount item(s) equipped',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
