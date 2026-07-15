/// Backend quest preferences from GET/PUT /profile. Only the fields the app
/// edits today; the backend has more (home coords, sharing flags) that pass
/// through untouched because PUT only sends what's provided.
class UserProfile {
  final double preferredRadiusKm;
  final int? preferredDifficulty;
  final List<String> preferredQuestTypes;

  const UserProfile({
    required this.preferredRadiusKm,
    this.preferredDifficulty,
    required this.preferredQuestTypes,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        preferredRadiusKm:
            (json['preferred_radius_km'] as num?)?.toDouble() ?? 2.0,
        preferredDifficulty: (json['preferred_difficulty'] as num?)?.toInt(),
        preferredQuestTypes: (json['preferred_quest_types'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['location', 'social', 'action'],
      );

  /// Body for PUT /profile — only the preference fields this app sets.
  Map<String, dynamic> toUpdateJson() => {
        'preferred_radius_km': preferredRadiusKm,
        if (preferredDifficulty != null)
          'preferred_difficulty': preferredDifficulty,
        'preferred_quest_types': preferredQuestTypes,
      };
}

class LifeStats {
  /// stat name -> points (e.g. social, creativity, exploration, knowledge).
  /// Kept as a map so the backend can evolve the set of stats.
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

  /// GET /profile/stats returns flat `*_xp` keys, e.g.
  /// { social_xp, creativity_xp, exploration_xp, knowledge_xp, fitness_xp }.
  factory LifeStats.fromJson(Map<String, dynamic> json) {
    final raw = (json['stats'] as Map<String, dynamic>?) ?? json;
    return LifeStats(
      raw.map((k, v) {
        final key = k.endsWith('_xp') ? k.substring(0, k.length - 3) : k;
        return MapEntry(key, (v as num?)?.toInt() ?? 0);
      }),
    );
  }

  /// Stat keys in display order (known order first, then any extras).
  List<String> get orderedKeys {
    final known = order.where(values.containsKey);
    final extra = values.keys.where((k) => !order.contains(k));
    return [...known, ...extra];
  }
}
