import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/quest_constants.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/local_cache.dart';

class SettingsState {
  final double radiusKm;
  final Set<String> categories; // enabled quest types
  final bool darkMode;
  final bool notificationsEnabled;
  final bool questReminders;
  final bool streakReminders;
  final TimeOfDay streakReminderTime;

  const SettingsState({
    required this.radiusKm,
    required this.categories,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.questReminders,
    required this.streakReminders,
    required this.streakReminderTime,
  });

  SettingsState copyWith({
    double? radiusKm,
    Set<String>? categories,
    bool? darkMode,
    bool? notificationsEnabled,
    bool? questReminders,
    bool? streakReminders,
    TimeOfDay? streakReminderTime,
  }) =>
      SettingsState(
        radiusKm: radiusKm ?? this.radiusKm,
        categories: categories ?? this.categories,
        darkMode: darkMode ?? this.darkMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        questReminders: questReminders ?? this.questReminders,
        streakReminders: streakReminders ?? this.streakReminders,
        streakReminderTime: streakReminderTime ?? this.streakReminderTime,
      );
}

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _kRadius = 'pref_radius_km';
  static const _kCategories = 'pref_categories';
  static const _kDarkMode = 'pref_dark_mode';
  static const _kNotificationsEnabled = 'pref_notifications_enabled';
  static const _kQuestReminders = 'pref_quest_reminders';
  static const _kStreakReminders = 'pref_streak_reminders';
  static const _kStreakReminderTime = 'pref_streak_reminder_time';
  static const _kLastCompletionDate = 'pref_last_quest_completion_date';
  static const _defaultCategories = {
    QuestType.location,
    QuestType.social,
    QuestType.action,
  };
  static const _defaultStreakTime = TimeOfDay(hour: 20, minute: 0);

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
    // Dark is the default theme; light is opt-in.
    final darkMode = cache.getBool(_kDarkMode) ?? true;
    // Notifications are opt-in: off until the user turns them on (and grants
    // OS permission), rather than surprising them with a permission prompt.
    final notificationsEnabled =
        cache.getBool(_kNotificationsEnabled) ?? false;
    final questReminders = cache.getBool(_kQuestReminders) ?? true;
    final streakReminders = cache.getBool(_kStreakReminders) ?? true;
    final streakReminderTime =
        _decodeTime(cache.getString(_kStreakReminderTime)) ??
            _defaultStreakTime;

    return SettingsState(
      radiusKm: radius,
      categories: categories,
      darkMode: darkMode,
      notificationsEnabled: notificationsEnabled,
      questReminders: questReminders,
      streakReminders: streakReminders,
      streakReminderTime: streakReminderTime,
    );
  }

  Future<void> setDarkMode(bool on) async {
    final current = state.value;
    if (current == null) return;
    await _cache?.setBool(_kDarkMode, on);
    state = AsyncData(current.copyWith(darkMode: on));
  }

  Future<void> setRadius(double km) async {
    final current = state.value;
    if (current == null) return;
    await _cache?.setString(_kRadius, km.toString());
    state = AsyncData(current.copyWith(radiusKm: km));
  }

  /// Replaces the enabled quest categories wholesale (set once by
  /// onboarding; not user-editable afterwards).
  Future<void> setCategories(Set<String> categories) async {
    final current = state.value;
    if (current == null) return;
    await _cache?.setString(_kCategories, categories.join(','));
    state = AsyncData(current.copyWith(categories: categories));
  }

  /// Turning this on requests OS permission first; the setting only flips to
  /// on if permission is granted. Throws [NotificationException] on denial
  /// so the settings screen can show an actionable message — the caller must
  /// catch it.
  Future<void> setNotificationsEnabled(bool on) async {
    final current = state.value;
    if (current == null) return;
    final service = ref.read(notificationServiceProvider);
    if (on) {
      await service.init();
      await service.requestPermission();
    } else {
      await service.cancelAllQuestReminders();
      await service.cancelStreakReminder();
    }
    await _cache?.setBool(_kNotificationsEnabled, on);
    final next = current.copyWith(notificationsEnabled: on);
    state = AsyncData(next);
    if (on) await _syncStreakReminder(next);
  }

  Future<void> setQuestReminders(bool on) async {
    final current = state.value;
    if (current == null) return;
    await _cache?.setBool(_kQuestReminders, on);
    state = AsyncData(current.copyWith(questReminders: on));
    if (!on) await ref.read(notificationServiceProvider).cancelAllQuestReminders();
  }

  Future<void> setStreakReminders(bool on) async {
    final current = state.value;
    if (current == null) return;
    await _cache?.setBool(_kStreakReminders, on);
    final next = current.copyWith(streakReminders: on);
    state = AsyncData(next);
    await _syncStreakReminder(next);
  }

  Future<void> setStreakReminderTime(TimeOfDay time) async {
    final current = state.value;
    if (current == null) return;
    await _cache?.setString(_kStreakReminderTime, _encodeTime(time));
    final next = current.copyWith(streakReminderTime: time);
    state = AsyncData(next);
    await _syncStreakReminder(next);
  }

  Future<void> _syncStreakReminder(SettingsState s) async {
    final service = ref.read(notificationServiceProvider);
    if (!s.notificationsEnabled || !s.streakReminders) {
      await service.cancelStreakReminder();
      return;
    }
    // Already completed a quest today (recorded by [recordQuestCompletedToday]
    // during this or an earlier session today) — nothing to remind about.
    if (_cache?.getString(_kLastCompletionDate) == _todayKey()) {
      await service.cancelStreakReminder();
      return;
    }
    await service.scheduleDailyStreakReminder(s.streakReminderTime);
  }

  /// Call whenever a quest completes. Marks today as "done" so reopening the
  /// app later today won't resurrect the streak reminder, and cancels any
  /// copy already scheduled for today.
  Future<void> recordQuestCompletedToday() async {
    await _cache?.setString(_kLastCompletionDate, _todayKey());
    await ref.read(notificationServiceProvider).cancelStreakReminder();
  }

  /// Re-syncs the streak reminder for "the app just opened" — schedules
  /// today's reminder unless one isn't warranted (settings off, or a quest
  /// was already completed today).
  Future<void> syncStreakReminderForAppOpen() async {
    final current = state.value;
    if (current == null) return;
    await _syncStreakReminder(current);
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static String _encodeTime(TimeOfDay t) => '${t.hour}:${t.minute}';

  static TimeOfDay? _decodeTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
