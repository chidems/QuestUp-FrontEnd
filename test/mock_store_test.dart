// Exercises the mock-mode purchase flow. Run with:
//   flutter test --dart-define=USE_MOCK_API=true test/mock_store_test.dart
// Without the define these tests skip (the API would hit the network).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quest_up/core/config/app_config.dart';
import 'package:quest_up/core/network/api_exception.dart';
import 'package:quest_up/core/storage/mock_economy.dart';
import 'package:quest_up/features/store/data/store_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = StoreApi(Dio());

  test('buy deducts coins, persists ownership, and guards the wallet',
      skip: !AppConfig.useMockApi ? 'requires USE_MOCK_API=true' : false,
      () async {
    SharedPreferences.setMockInitialValues({});

    final items = await api.getItems();
    expect(items, hasLength(84));
    expect(items.where((i) => i.isOwned), isEmpty);

    // item_001 (Squire's Sword): common, 40 coins.
    await api.buy('item_001');
    expect(await MockEconomy.coinsSpent(), 40);
    expect(await MockEconomy.ownedItemIds(), {'item_001'});
    expect(
      (await api.getItems()).firstWhere((i) => i.id == 'item_001').isOwned,
      isTrue,
    );

    // Double-purchase is rejected.
    await expectLater(api.buy('item_001'), throwsA(isA<ApiException>()));

    // Overspending is rejected: balance is now 310, legendary costs 600.
    final legendary =
        (await api.getItems()).firstWhere((i) => i.rarity == 'legendary');
    await expectLater(api.buy(legendary.id), throwsA(isA<ApiException>()));
    expect(await MockEconomy.coinsSpent(), 40);
  });
}
