import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// Shows an avatar item's image, or a type-based icon placeholder until real
/// pixel-art assets are wired in.
class ItemThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String itemType;
  final double size;

  const ItemThumbnail({
    super.key,
    required this.imageUrl,
    required this.itemType,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final url = imageUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => _placeholder(palette),
            )
          : _placeholder(palette),
    );
  }

  Widget _placeholder(AppPalette palette) => Center(
        child: Icon(_iconFor(itemType),
            color: palette.textMuted, size: size * 0.45),
      );

  IconData _iconFor(String type) {
    switch (type) {
      case 'hat':
        return Icons.school;
      case 'top':
      case 'bottom':
        return Icons.checkroom;
      case 'shoes':
        return Icons.ice_skating;
      case 'weapon':
        return Icons.gavel;
      case 'accessory':
        return Icons.diamond;
      case 'background':
        return Icons.wallpaper;
      default:
        return Icons.category;
    }
  }
}
