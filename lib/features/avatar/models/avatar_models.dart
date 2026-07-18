import 'dart:convert';

import '../data/asset_catalog.dart';

class ItemType {
  static const String top = 'top';
  static const String bottom = 'bottom';

  /// Held props sold in the shop (weapons, plushies, instruments...).
  static const String item = 'item';

  static String label(String type) =>
      type.isEmpty ? type : '${type[0].toUpperCase()}${type.substring(1)}';
}

/// A purchasable shop item (held prop). `asset` is the bundled sprite path in
/// mock mode; `imageUrl` is used when a real backend serves art instead.
class AvatarItem {
  final String id;
  final String name;
  final String? description;
  final String itemType;
  final String rarity;
  final int priceCoins;
  final String? imageUrl;
  final String? asset;
  final bool isOwned;
  final bool isEquipped;

  const AvatarItem({
    required this.id,
    required this.name,
    this.description,
    required this.itemType,
    required this.rarity,
    required this.priceCoins,
    this.imageUrl,
    this.asset,
    this.isOwned = false,
    this.isEquipped = false,
  });

  /// Whether this item has real art to show — a bundled sprite or a hosted
  /// image — rather than falling back to the generic placeholder glyph.
  bool get hasArt => asset != null || (imageUrl?.isNotEmpty ?? false);

  AvatarItem copyWith({bool? isOwned, bool? isEquipped}) => AvatarItem(
        id: id,
        name: name,
        description: description,
        itemType: itemType,
        rarity: rarity,
        priceCoins: priceCoins,
        imageUrl: imageUrl,
        asset: asset,
        isOwned: isOwned ?? this.isOwned,
        isEquipped: isEquipped ?? this.isEquipped,
      );

  factory AvatarItem.fromJson(Map<String, dynamic> json) => AvatarItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        itemType: json['item_type'] as String? ?? ItemType.item,
        rarity: json['rarity'] as String? ?? 'common',
        priceCoins: (json['price_coins'] as num?)?.toInt() ?? 0,
        imageUrl: json['image_url'] as String?,
        // The real backend has no image hosting yet, but every seeded item
        // carries a stable pixel_asset_key. Most items reuse the existing
        // 84-item mock catalog (pixel_asset_key == that catalog's id, e.g.
        // 'item_017') and resolve to its bundled art; items with no catalog
        // counterpart fall back to the placeholder glyph, same as mock mode.
        asset: AssetCatalog.itemById[json['pixel_asset_key'] as String?]?.asset,
        isOwned: json['is_owned'] as bool? ?? false,
        isEquipped: json['is_equipped'] as bool? ?? false,
      );
}

const _unset = Object();

/// The user's avatar look: free identity layers (skin/eyes/hair/clothes) plus
/// one equipped held item. Ids reference asset_catalog.g.dart entries.
class AvatarAppearance {
  final String skinId;
  final String eyesId;
  final String hairId;
  final String? topId;
  final String? bottomId;
  final String? itemId;

  const AvatarAppearance({
    required this.skinId,
    required this.eyesId,
    required this.hairId,
    this.topId,
    this.bottomId,
    this.itemId,
  });

  /// Starter look for new players.
  static const defaults = AvatarAppearance(
    skinId: 'skin_light',
    eyesId: 'eyes_brown',
    hairId: 'hair_001',
    topId: 'rpg_neutral_top_tops_common_001',
    bottomId: 'modern_masculine_bottom_bottoms_common_001',
  );

  /// copyWith where passing `null` explicitly clears an optional slot.
  AvatarAppearance copyWith({
    String? skinId,
    String? eyesId,
    String? hairId,
    Object? topId = _unset,
    Object? bottomId = _unset,
    Object? itemId = _unset,
  }) =>
      AvatarAppearance(
        skinId: skinId ?? this.skinId,
        eyesId: eyesId ?? this.eyesId,
        hairId: hairId ?? this.hairId,
        topId: topId == _unset ? this.topId : topId as String?,
        bottomId: bottomId == _unset ? this.bottomId : bottomId as String?,
        itemId: itemId == _unset ? this.itemId : itemId as String?,
      );

  String encode() => jsonEncode({
        'skin': skinId,
        'eyes': eyesId,
        'hair': hairId,
        'top': topId,
        'bottom': bottomId,
        'item': itemId,
      });

  factory AvatarAppearance.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return AvatarAppearance(
      skinId: json['skin'] as String? ?? defaults.skinId,
      eyesId: json['eyes'] as String? ?? defaults.eyesId,
      hairId: json['hair'] as String? ?? defaults.hairId,
      topId: json['top'] as String?,
      bottomId: json['bottom'] as String?,
      // Falls back to the old two-hand keys for avatars saved before the
      // single-item change.
      itemId: json['item'] as String? ??
          json['right_item'] as String? ??
          json['left_item'] as String?,
    );
  }
}
