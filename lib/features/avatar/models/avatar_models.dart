class ItemType {
  static const String hat = 'hat';
  static const String top = 'top';
  static const String bottom = 'bottom';
  static const String shoes = 'shoes';
  static const String weapon = 'weapon';
  static const String accessory = 'accessory';
  static const String background = 'background';

  /// Back-to-front order used when layering equipped items in the preview.
  static const List<String> layerOrder = [
    background,
    bottom,
    top,
    shoes,
    weapon,
    hat,
    accessory,
  ];

  /// Filter / grouping order shown in UI.
  static const List<String> all = [
    hat,
    top,
    bottom,
    shoes,
    weapon,
    accessory,
    background,
  ];

  static String label(String type) =>
      type.isEmpty ? type : '${type[0].toUpperCase()}${type.substring(1)}';
}

class AvatarItem {
  final String id;
  final String name;
  final String? description;
  final String itemType;
  final String rarity;
  final int priceCoins;
  final String? imageUrl;
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
    this.isOwned = false,
    this.isEquipped = false,
  });

  factory AvatarItem.fromJson(Map<String, dynamic> json) => AvatarItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        itemType: json['item_type'] as String? ?? 'accessory',
        rarity: json['rarity'] as String? ?? 'common',
        priceCoins: (json['price_coins'] as num?)?.toInt() ?? 0,
        imageUrl: json['image_url'] as String?,
        isOwned: json['is_owned'] as bool? ?? false,
        isEquipped: json['is_equipped'] as bool? ?? false,
      );
}

/// The user's currently equipped look.
class Avatar {
  final List<AvatarItem> equipped;

  const Avatar({required this.equipped});

  factory Avatar.fromJson(Map<String, dynamic> json) {
    final items = (json['equipped'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        const [];
    return Avatar(
      equipped: items
          .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Combined payload for the avatar screen: equipped look + owned inventory.
class AvatarData {
  final Avatar avatar;
  final List<AvatarItem> inventory;

  const AvatarData({required this.avatar, required this.inventory});
}
