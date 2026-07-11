import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../features/quests/models/quest_models.dart';

/// Thrown when notification permission is denied. The settings screen uses
/// [canOpenSettings] to decide whether to offer an "Open settings" action.
class NotificationException implements Exception {
  final String message;
  final bool canOpenSettings;

  const NotificationException(this.message, {this.canOpenSettings = false});

  @override
  String toString() => message;
}

const _kQuestChannelId = 'quest_deadlines';
const _kStreakChannelId = 'streak_reminders';

/// Fixed id for the (single, always-replaced) daily streak reminder, kept out
/// of the range `String.hashCode & 0x7fffffff` can produce for quest ids.
const _kStreakReminderId = 0x70000000;

const _kDefaultQuestLeadTime = Duration(hours: 1);

/// Schedules local (on-device) notifications for quest deadlines and daily
/// streak reminders. No push infrastructure — everything is one-shot,
/// plugin-managed OS alarms.
///
/// Plain class, not a service locator: instantiate it and wire it through
/// Riverpod providers, same as [LocationService].
///
/// Timezone note: this app has no native timezone-name plugin (out of scope
/// — see class doc on the caller side), so [tz.local] is fixed to UTC rather
/// than the device's real IANA zone. Schedule instants are computed from
/// regular local [DateTime] arithmetic (always correct — Dart's local
/// `DateTime` already reflects the OS's real timezone) and then wrapped with
/// `TZDateTime.from(instant, tz.local)`, which preserves the absolute instant
/// regardless of what `tz.local` is. This is correct for the one-shot quest
/// reminders. The daily streak reminder is rescheduled fresh from real local
/// time every app open and every completion, so the only residual risk is a
/// same-day drift of the DST delta (~1 hour) on the exact day a DST
/// transition happens while the app hasn't been reopened — self-corrects on
/// next open.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _kQuestChannelId,
      'Quest deadlines',
      description: 'Reminders that a quest is about to expire',
      importance: Importance.high,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _kStreakChannelId,
      'Streak reminders',
      description: 'A daily nudge to keep your streak alive',
      importance: Importance.defaultImportance,
    ));

    _initialized = true;
  }

  /// Requests OS notification permission (iOS: alert/badge/sound; Android
  /// 13+: POST_NOTIFICATIONS — a no-op granted-by-default on older Android).
  /// Throws [NotificationException] if denied.
  Future<void> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (granted != true) {
        throw const NotificationException(
          'Notification permission is needed for quest and streak reminders. '
          'Enable it in settings.',
          canOpenSettings: true,
        );
      }
      return;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (granted != true) {
        throw const NotificationException(
          'Notification permission is needed for quest and streak reminders. '
          'Enable it in settings.',
          canOpenSettings: true,
        );
      }
    }
  }

  /// Schedules a one-shot reminder [leadTime] before [quest.expiresAt].
  /// Covers weekly-quest deadlines too — [Quest] is the same model either
  /// way, so there's no separate weekly path.
  ///
  /// No-ops when the quest has no deadline (the backend doesn't always send
  /// `expires_at` yet), isn't active/accepted, or the reminder instant has
  /// already passed.
  Future<void> scheduleQuestDeadlineReminder(
    Quest quest, {
    Duration leadTime = _kDefaultQuestLeadTime,
  }) async {
    final expiresAt = quest.expiresAt;
    if (expiresAt == null) return;
    if (quest.status != 'active' && quest.status != 'accepted') {
      await cancelReminder(quest.id);
      return;
    }

    final fireAt = expiresAt.subtract(leadTime);
    if (fireAt.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _questNotificationId(quest.id),
      'Quest deadline approaching',
      '"${quest.title}" expires soon — complete it before it\'s gone!',
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kQuestChannelId,
          'Quest deadlines',
          channelDescription: 'Reminders that a quest is about to expire',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String questId) =>
      _plugin.cancel(_questNotificationId(questId));

  /// Cancels every currently-pending quest deadline reminder (used when the
  /// user turns the "quest deadline reminders" setting off). Uses the
  /// plugin's own pending-request introspection rather than tracking ids
  /// ourselves, and leaves the streak reminder alone.
  Future<void> cancelAllQuestReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id != _kStreakReminderId) {
        await _plugin.cancel(request.id);
      }
    }
  }

  /// Schedules today's streak reminder at [time] local time, replacing any
  /// previously-scheduled one. No-ops if [time] has already passed today —
  /// there's no meaningful "today" reminder left to show in that case.
  Future<void> scheduleDailyStreakReminder(TimeOfDay time) async {
    await cancelStreakReminder();

    final now = DateTime.now();
    final fireAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (fireAt.isBefore(now)) return;

    await _plugin.zonedSchedule(
      _kStreakReminderId,
      'Keep your streak alive!',
      "You haven't completed a quest today — don't lose your streak.",
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kStreakChannelId,
          'Streak reminders',
          channelDescription: 'A daily nudge to keep your streak alive',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelStreakReminder() => _plugin.cancel(_kStreakReminderId);

  /// Opens the app's OS settings page. Reuses `geolocator` (already a
  /// dependency for location) rather than adding `permission_handler` just
  /// for this one call — both packages' "open app settings" intents open the
  /// same generic per-app settings screen.
  Future<void> openSettings() => Geolocator.openAppSettings();

  int _questNotificationId(String questId) => questId.hashCode & 0x7fffffff;
}
