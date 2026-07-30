import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quest_up/features/auth/models/auth_models.dart';
import 'package:quest_up/features/auth/providers/auth_provider.dart';
import 'package:quest_up/features/quests/models/quest_models.dart';
import 'package:quest_up/features/quests/providers/quest_feed_provider.dart';
import 'package:quest_up/features/weekly/models/weekly_models.dart';
import 'package:quest_up/features/weekly/presentation/weekly_quest_screen.dart';
import 'package:quest_up/features/weekly/providers/weekly_provider.dart';

const _me = User(
  id: 'me',
  email: 'me@example.com',
  displayName: 'Me',
  level: 1,
  totalXp: 0,
  coins: 0,
  currentStreak: 0,
  longestStreak: 0,
);

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => _me;
}

class _FakeFeedNotifier extends QuestFeedNotifier {
  @override
  Future<QuestFeed> build() async => const QuestFeed(normalQuests: []);
}

class _FixedWeeklyNotifier extends WeeklyNotifier {
  _FixedWeeklyNotifier(this.data);
  final WeeklyData data;

  @override
  Future<WeeklyData> build() async => data;
}

Quest _weeklyQuest() => const Quest(
      id: '900',
      title: 'Sketch the view',
      description: '',
      questType: 'action',
      source: 'weekly',
      difficulty: 3,
      xpReward: 150,
      coinReward: 100,
      status: 'active',
      isWeekly: true,
    );

Future<void> _pumpScreen(
  WidgetTester tester,
  WeeklyData data, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_FakeAuthNotifier.new),
        questFeedProvider.overrideWith(_FakeFeedNotifier.new),
        weeklyProvider.overrideWith(() => _FixedWeeklyNotifier(data)),
      ],
      child: const MaterialApp(home: WeeklyQuestScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WeeklyQuestScreen community photos', () {
    testWidgets('the current user\'s own post is labeled "You", not their '
        'raw user id', (tester) async {
      await _pumpScreen(
        tester,
        WeeklyData(
          status: WeeklyQuestStatus(quest: _weeklyQuest(), isCompleted: true),
          photos: const [
            WeeklyPhotoPost(
              id: 'p1',
              userId: 'me',
              userDisplayName: 'A Fellow Adventurer',
              photoUrl: 'local://uploads/me/photo.jpg',
              questTitle: 'Sketch the view',
            ),
          ],
        ),
      );

      expect(find.text('You'), findsOneWidget);
      expect(find.text('A Fellow Adventurer'), findsNothing);
      expect(find.textContaining('me'), findsNothing);
    });

    testWidgets('another user\'s post shows a friendly label, never their '
        'raw user id', (tester) async {
      await _pumpScreen(
        tester,
        WeeklyData(
          status: WeeklyQuestStatus(quest: _weeklyQuest(), isCompleted: false),
          photos: const [
            WeeklyPhotoPost(
              id: 'p1',
              userId: 'someone-else-uuid',
              userDisplayName: 'A Fellow Adventurer',
              photoUrl: 'local://uploads/someone-else-uuid/photo.jpg',
              questTitle: 'Sketch the view',
            ),
          ],
        ),
      );

      expect(find.text('A Fellow Adventurer'), findsOneWidget);
      expect(find.textContaining('someone-else-uuid'), findsNothing);
    });

    testWidgets('a local:// photo (no real hosting yet) shows an honest '
        'placeholder instead of a broken-image icon', (tester) async {
      await _pumpScreen(
        tester,
        WeeklyData(
          status: WeeklyQuestStatus(quest: _weeklyQuest(), isCompleted: true),
          photos: const [
            WeeklyPhotoPost(
              id: 'p1',
              userId: 'me',
              userDisplayName: 'A Fellow Adventurer',
              photoUrl: 'local://uploads/me/photo.jpg',
              questTitle: 'Sketch the view',
            ),
          ],
        ),
      );

      expect(find.text('Photo pending upload support'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsNothing);
    });

    testWidgets(
        'shows the real photo on the device that shared it, instead of the '
        'pending placeholder, using the locally cached file path',
        (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('weekly_photo');
      final file = File('${tempDir.path}/photo.jpg')
        ..writeAsBytesSync(const [0, 1, 2, 3]);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      await _pumpScreen(
        tester,
        WeeklyData(
          status: WeeklyQuestStatus(quest: _weeklyQuest(), isCompleted: true),
          photos: const [
            WeeklyPhotoPost(
              id: 'p1',
              userId: 'me',
              userDisplayName: 'A Fellow Adventurer',
              photoUrl: 'local://uploads/me/photo.jpg',
              questTitle: 'Sketch the view',
            ),
          ],
        ),
        prefs: {'local_shared_photo_p1': file.path},
      );

      expect(find.text('Photo pending upload support'), findsNothing);
      expect(find.byIcon(Icons.photo_camera_back), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
