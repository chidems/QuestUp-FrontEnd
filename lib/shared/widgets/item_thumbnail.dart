import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import 'pixel_glyph.dart';

/// Hand-drawn 12x12 pixel sprites per item type ('X' = filled cell), shown
/// when no art is available for an item.
const _topGlyph = [
  '............',
  '.XXX....XXX.',
  'XXXXXXXXXXXX',
  'XXXXXXXXXXXX',
  'XX.XXXXXX.XX',
  '...XXXXXX...',
  '...XXXXXX...',
  '...XXXXXX...',
  '...XXXXXX...',
  '............',
  '............',
  '............',
];

const _bottomGlyph = [
  '............',
  '..XXXXXXXX..',
  '..XXXXXXXX..',
  '..XXXXXXXX..',
  '..XXX..XXX..',
  '..XXX..XXX..',
  '..XXX..XXX..',
  '..XXX..XXX..',
  '..XXX..XXX..',
  '..XXX..XXX..',
  '............',
  '............',
];

const _chestGlyph = [
  '............',
  '.XXXXXXXXXX.',
  '.XX......XX.',
  '.XXXXXXXXXX.',
  '.XX......XX.',
  '.XX..XX..XX.',
  '.XX..XX..XX.',
  '.XX......XX.',
  '.XXXXXXXXXX.',
  '............',
  '............',
  '............',
];

/// Shows an item's art: a bundled sprite when [asset] is set, a network image
/// when [imageUrl] is set, or a type-based pixel glyph fallback.
class ItemThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? asset;
  final String itemType;
  final double size;

  const ItemThumbnail({
    super.key,
    this.imageUrl,
    this.asset,
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
        borderRadius: AppRadius.rSmall,
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: switch (asset) {
        final a? => Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              a,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
        _ => url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => _placeholder(palette),
              )
            : _placeholder(palette),
      },
    );
  }

  Widget _placeholder(AppPalette palette) => Center(
        child: PixelGlyph(_glyphFor(itemType),
            color: palette.textMuted, size: size * 0.55),
      );

  List<String> _glyphFor(String type) {
    switch (type) {
      case 'top':
        return _topGlyph;
      case 'bottom':
        return _bottomGlyph;
      default:
        return _chestGlyph;
    }
  }
}
