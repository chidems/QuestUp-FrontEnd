class LifeStats {
  /// stat name -> points (e.g. social, creativity, exploration, knowledge,
  /// fitness). Kept as a map so the backend can evolve the set of stats.
  final Map<String, int> values;

  const LifeStats(this.values);

  /// Display order; any extra keys from the backend are appended after these.
  static const List<String> order = [
    'social',
    'creativity',
    'exploration',
    'knowledge',
    'fitness',
  ];

  factory LifeStats.fromJson(Map<String, dynamic> json) {
    final raw = (json['stats'] as Map<String, dynamic>?) ?? json;
    return LifeStats(
      raw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
    );
  }

  /// Stat keys in display order (known order first, then any extras).
  List<String> get orderedKeys {
    final known = order.where(values.containsKey);
    final extra = values.keys.where((k) => !order.contains(k));
    return [...known, ...extra];
  }
}
