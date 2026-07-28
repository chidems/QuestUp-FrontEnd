import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/mock_economy.dart';
import '../../avatar/data/asset_catalog.dart';
import '../../avatar/models/avatar_models.dart';

class StoreApi {
  final Dio _dio;

  StoreApi(this._dio);

  Future<List<AvatarItem>> getItems() async {
    if (AppConfig.useMockApi) {
      final owned = await MockEconomy.ownedItemIds();
      return [
        for (final item in kItems)
          AvatarItem(
            id: item.id,
            name: item.name,
            itemType: ItemType.item,
            rarity: item.rarity,
            priceCoins: item.priceCoins,
            asset: item.asset,
            // Mock ids are catalog ids already.
            assetKey: item.id,
            isOwned: owned.contains(item.id),
          ),
      ];
    }
    try {
      final response = await _dio.get('/store/items');
      final data = response.data;
      final list = data is List ? data : (data['items'] as List? ?? []);
      return list
          .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  /// Ids of the avatar items the user owns. The store listing carries no
  /// ownership flag — the backend keeps that in a separate inventory — so this
  /// is what makes a purchase show as owned.
  Future<Set<String>> getOwnedItemIds() async {
    if (AppConfig.useMockApi) return MockEconomy.ownedItemIds();
    try {
      final response = await _dio.get('/inventory');
      final data = response.data;
      final list = data is List ? data : (data['items'] as List? ?? []);
      final ids = <String>{};
      for (final row in list) {
        final id = (row as Map<String, dynamic>)['avatar_item_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
      return ids;
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> buy(String itemId) async {
    if (AppConfig.useMockApi) {
      final item = AssetCatalog.itemById[itemId];
      if (item == null) throw ApiException('Unknown item.');
      final owned = await MockEconomy.ownedItemIds();
      if (owned.contains(itemId)) throw ApiException('Already owned.');
      final balance = MockEconomy.baseCoins - await MockEconomy.coinsSpent();
      if (item.priceCoins > balance) throw ApiException('Not enough coins.');
      await MockEconomy.addSpent(item.priceCoins);
      await MockEconomy.addOwnedItem(itemId);
      return;
    }
    try {
      await _dio.post('/store/items/$itemId/purchase');
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }
}
