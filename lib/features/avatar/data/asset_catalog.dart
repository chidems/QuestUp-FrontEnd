import 'asset_catalog.g.dart';

export 'asset_catalog.g.dart';

/// Id-keyed lookups over the generated sprite catalog.
class AssetCatalog {
  AssetCatalog._();

  static final Map<String, SpriteAsset> skinById = _byId(kSkinTones);
  static final Map<String, SpriteAsset> eyesById = _byId(kEyeColors);
  static final Map<String, HairAsset> hairById = _byId(kHairStyles);
  static final Map<String, ClothingAsset> clothingById = _byId(kClothes);
  static final Map<String, ItemAsset> itemById = _byId(kItems);

  static Map<String, T> _byId<T extends SpriteAsset>(List<T> list) =>
      {for (final a in list) a.id: a};
}
