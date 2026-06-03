import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/avatar_models.dart';

/// Mock catalog shared by avatar (inventory) and store. Owned items make up the
/// inventory; `imageUrl` is null until real pixel-art assets are added.
const List<AvatarItem> mockCatalog = [
  AvatarItem(
    id: 'i1',
    name: 'Wizard Hat',
    description: 'A pointy hat humming with arcane focus.',
    itemType: ItemType.hat,
    rarity: 'rare',
    priceCoins: 120,
    isOwned: true,
    isEquipped: true,
  ),
  AvatarItem(
    id: 'i2',
    name: 'Leather Tunic',
    description: 'Sturdy starter gear for any adventurer.',
    itemType: ItemType.top,
    rarity: 'common',
    priceCoins: 40,
    isOwned: true,
    isEquipped: true,
  ),
  AvatarItem(
    id: 'i3',
    name: 'Adventurer Pants',
    description: 'Comfortable trousers built for long walks.',
    itemType: ItemType.bottom,
    rarity: 'common',
    priceCoins: 30,
    isOwned: true,
  ),
  AvatarItem(
    id: 'i4',
    name: 'Travel Boots',
    description: 'Worn-in boots that never give you blisters.',
    itemType: ItemType.shoes,
    rarity: 'uncommon',
    priceCoins: 60,
  ),
  AvatarItem(
    id: 'i5',
    name: 'Oak Staff',
    description: 'Channel your inner mage.',
    itemType: ItemType.weapon,
    rarity: 'epic',
    priceCoins: 250,
  ),
  AvatarItem(
    id: 'i6',
    name: 'Enchanted Forest',
    description: 'A mystical backdrop for your profile.',
    itemType: ItemType.background,
    rarity: 'rare',
    priceCoins: 150,
  ),
  AvatarItem(
    id: 'i7',
    name: 'Golden Crown',
    description: 'Fit for the ruler of the realm.',
    itemType: ItemType.hat,
    rarity: 'legendary',
    priceCoins: 500,
  ),
];

class AvatarApi {
  final Dio _dio;

  AvatarApi(this._dio);

  Future<Avatar> getAvatar() async {
    if (AppConfig.useMockApi) {
      return Avatar(
        equipped: mockCatalog.where((i) => i.isEquipped).toList(),
      );
    }
    try {
      final response = await _dio.get('/avatar');
      return Avatar.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<List<AvatarItem>> getInventory() async {
    if (AppConfig.useMockApi) {
      return mockCatalog.where((i) => i.isOwned).toList();
    }
    try {
      final response = await _dio.get('/avatar/inventory');
      final data = response.data;
      final list = data is List ? data : (data['items'] as List? ?? []);
      return list
          .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> equip(String itemId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.put('/avatar/equip', data: {'item_id': itemId});
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }
}
