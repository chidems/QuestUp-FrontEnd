import 'package:shared_preferences/shared_preferences.dart';

/// Persisted wallet + inventory for mock mode, so shop purchases survive
/// restarts and the HUD coin balance actually goes down. The real backend
/// owns this state outside mock mode.
class MockEconomy {
  MockEconomy._();

  /// Starting balance of the mock user (matches the mock auth profile).
  static const int baseCoins = 350;

  static const _kSpent = 'mock_coins_spent';
  static const _kOwned = 'mock_owned_items';

  static Future<int> coinsSpent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSpent) ?? 0;
  }

  static Future<void> addSpent(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSpent, (prefs.getInt(_kSpent) ?? 0) + amount);
  }

  static Future<Set<String>> ownedItemIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kOwned) ?? const []).toSet();
  }

  static Future<void> addOwnedItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = (prefs.getStringList(_kOwned) ?? const []).toSet()..add(id);
    await prefs.setStringList(_kOwned, owned.toList());
  }
}
