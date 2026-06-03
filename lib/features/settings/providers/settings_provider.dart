import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/quest_constants.dart';
import '../../../core/storage/local_cache.dart';

class SettingsState {
  final double radiusKm;
  final Set<String> categories; // enabled quest types

  const SettingsState({required this.radiusKm, required this.categories});

  SettingsState copyWith({double? radiusKm, Set<String>? categories}) =>
      SettingsState(
        radiusKm: radiusKm ?? this.radiusKm,
        categories: categories ?? this.categories,
      );
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _kRadius = 'pref_radius_km';
  static const _kCategories = 'pref_categories';
  static const _defaultCategories = {
    QuestType.location,
    QuestType.social,
    QuestType.action,
  };

  LocalCache? _cache;

  @override
  Future<SettingsState> build() async {
    final cache = LocalCache();
    await cache.init();
    _cache = cache;

    final radius = double.tryParse(cache.getString(_kRadius) ?? '') ?? 2.0;
    final stored = cache.getString(_kCategories);
    final categories = stored == null
        ? _defaultCategories
        : (stored.isEmpty ? <String>{} : stored.split(',').toSet());

    return SettingsState(radiusKm: radius, categories: categories);
  }

  Future<void> setRadius(double km) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _cache?.setString(_kRadius, km.toString());
    state = AsyncData(current.copyWith(radiusKm: km));
  }

  Future<void> toggleCategory(String type) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = {...current.categories};
    next.contains(type) ? next.remove(type) : next.add(type);
    await _cache?.setString(_kCategories, next.join(','));
    state = AsyncData(current.copyWith(categories: next));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
