import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quest_up/features/avatar/data/asset_catalog.dart';
import 'package:quest_up/features/avatar/models/avatar_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog has the expected sprite counts and unique ids', () {
    expect(kSkinTones, hasLength(16));
    // 24 eye sprites minus 6 near-duplicate colors pruned from the catalog.
    expect(kEyeColors, hasLength(18));
    expect(kHairStyles, hasLength(112));
    expect(kClothes, hasLength(465));
    expect(kItems, hasLength(84));

    final all = [...kSkinTones, ...kEyeColors, ...kHairStyles, ...kClothes, ...kItems];
    expect({for (final a in all) a.id}, hasLength(all.length));
  });

  test('every hair sprite has a known color group', () {
    final colors = kHairColorLabels.keys.toSet();
    for (final h in kHairStyles) {
      expect(colors, contains(h.color), reason: '${h.id} -> ${h.color}');
    }
    // Every offered color group actually has at least one style.
    for (final c in colors) {
      expect(kHairStyles.where((h) => h.color == c), isNotEmpty, reason: c);
    }
  });

  test('pruned eye colors are absent', () {
    final ids = {for (final e in kEyeColors) e.id};
    for (final pruned in const [
      'eyes_cyan',
      'eyes_turquoise',
      'eyes_ice_blue',
      'eyes_royal_blue',
      'eyes_violet',
      'eyes_rose',
    ]) {
      expect(ids, isNot(contains(pruned)));
    }
  });

  test('default appearance ids resolve in the catalog', () {
    const d = AvatarAppearance.defaults;
    expect(AssetCatalog.skinById[d.skinId], isNotNull);
    expect(AssetCatalog.eyesById[d.eyesId], isNotNull);
    expect(AssetCatalog.hairById[d.hairId], isNotNull);
    expect(AssetCatalog.clothingById[d.topId], isNotNull);
    expect(AssetCatalog.clothingById[d.bottomId], isNotNull);
  });

  test('appearance encode/decode round-trips, null slots preserved', () {
    const a = AvatarAppearance(
      skinId: 'skin_olive',
      eyesId: 'eyes_teal',
      hairId: 'hair_042',
      topId: null,
      bottomId: 'modern_feminine_bottom_bottoms_uncommon_003',
      itemId: 'item_084',
    );
    final b = AvatarAppearance.decode(a.encode());
    expect(b.skinId, a.skinId);
    expect(b.eyesId, a.eyesId);
    expect(b.hairId, a.hairId);
    expect(b.topId, isNull);
    expect(b.bottomId, a.bottomId);
    expect(b.itemId, a.itemId);
  });

  test('copyWith(null) clears optional slots', () {
    const d = AvatarAppearance.defaults;
    final bare = d.copyWith(topId: null, bottomId: null);
    expect(bare.topId, isNull);
    expect(bare.bottomId, isNull);
    expect(d.copyWith().topId, d.topId);
  });

  test('every catalog asset is bundled and loadable', () async {
    final all = [...kSkinTones, ...kEyeColors, ...kHairStyles, ...kClothes, ...kItems];
    for (final sprite in all) {
      final data = await rootBundle.load(sprite.asset);
      expect(data.lengthInBytes, greaterThan(0), reason: sprite.asset);
    }
  });
}
