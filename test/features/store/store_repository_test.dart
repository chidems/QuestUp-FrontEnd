import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_up/features/avatar/models/avatar_models.dart';
import 'package:quest_up/features/store/data/store_api.dart';
import 'package:quest_up/features/store/data/store_repository.dart';

/// Serves a fixed catalog and inventory, standing in for the two endpoints the
/// repository has to stitch together.
class _FakeApi extends StoreApi {
  _FakeApi({required this.items, required this.owned}) : super(Dio());

  final List<AvatarItem> items;
  final Set<String> owned;

  @override
  Future<List<AvatarItem>> getItems() async => items;

  @override
  Future<Set<String>> getOwnedItemIds() async => owned;
}

AvatarItem _item(
  String id, {
  String? asset = 'assets/items/x.png',
  Object? assetKey = _useDefault,
}) =>
    AvatarItem(
      id: id,
      name: 'Item $id',
      itemType: ItemType.item,
      rarity: 'common',
      priceCoins: 10,
      asset: asset,
      assetKey: assetKey == _useDefault ? 'item_$id' : assetKey as String?,
    );

const _useDefault = Object();

void main() {
  group('StoreRepository.getItems', () {
    test('marks items in the inventory as owned', () async {
      // The store listing itself reports no ownership — isOwned defaults to
      // false — so this can only come from the inventory call.
      final repo = StoreRepository(
        _FakeApi(items: [_item('001'), _item('002')], owned: {'001'}),
      );

      final result = await repo.getItems();

      expect(result.firstWhere((i) => i.id == '001').isOwned, isTrue);
      expect(result.firstWhere((i) => i.id == '002').isOwned, isFalse);
    });

    test('still hides items that have no art', () async {
      final repo = StoreRepository(
        _FakeApi(
          items: [_item('001'), _item('002', asset: null)],
          owned: const {},
        ),
      );

      expect((await repo.getItems()).map((i) => i.id), ['001']);
    });

    test('owning an item it cannot render does not resurrect it', () async {
      final repo = StoreRepository(
        _FakeApi(items: [_item('002', asset: null)], owned: {'002'}),
      );

      expect(await repo.getItems(), isEmpty);
    });
  });

  group('AvatarItem.isHoldable', () {
    test('true for a real held-item catalog key', () {
      // item_001 is Squire's Sword in the bundled catalog.
      expect(_item('x', assetKey: 'item_001').isHoldable, isTrue);
    });

    test('false for backend items with no held-item slot', () {
      // The backend sells these, but the avatar has nowhere to put them.
      for (final key in ['explorer_hat', 'weekly_cape', 'trophy_badge']) {
        expect(_item('x', assetKey: key).isHoldable, isFalse, reason: key);
      }
    });

    test('falls back to the id, so mock catalog ids still hold', () {
      // Mock mode builds items whose id is the catalog id itself.
      expect(_item('item_002', assetKey: null).isHoldable, isTrue);
    });
  });
}
