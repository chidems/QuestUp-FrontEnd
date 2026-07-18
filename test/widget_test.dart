import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quest_up/features/quests/models/quest_models.dart';
import 'package:quest_up/features/quests/presentation/quest_card.dart';
import 'package:quest_up/shared/widgets/weekly_quest_card.dart';
import 'package:quest_up/features/avatar/models/avatar_models.dart';
import 'package:quest_up/features/store/presentation/item_card.dart';
import 'package:quest_up/features/npc/models/npc_models.dart';
import 'package:quest_up/features/achievements/models/achievement_models.dart';
import 'package:quest_up/features/profile/models/profile_models.dart';
import 'package:quest_up/shared/widgets/pixel_button.dart';

ItemCard _itemCard(AvatarItem item, {bool canAfford = true}) => ItemCard(
      item: item,
      canAfford: canAfford,
      onBuy: () {},
    );

const _weeklyQuest = Quest(
  id: '900',
  title: 'Sketch the view from a rooftop',
  description: 'Head somewhere high and sketch what you see.',
  questType: 'action',
  source: 'weekly',
  difficulty: 3,
  xpReward: 150,
  coinReward: 100,
  status: 'active',
  isWeekly: true,
);

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('QuestCard shows title and rewards', (tester) async {
    const quest = Quest(
      id: '1',
      title: 'Explore a new cafe',
      description: 'Find a cafe you have never visited.',
      questType: 'location',
      source: 'normal',
      difficulty: 1,
      xpReward: 50,
      coinReward: 20,
      status: 'active',
      distanceMeters: 420,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestCard(quest: quest, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Explore a new cafe'), findsOneWidget);
    expect(find.text('50 XP'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('420 m'), findsOneWidget);
  });

  testWidgets('QuestCard tap fires callback', (tester) async {
    var tapped = false;
    const quest = Quest(
      id: '1',
      title: 'Do 20 push-ups',
      description: 'In a park.',
      questType: 'action',
      source: 'normal',
      difficulty: 2,
      xpReward: 80,
      coinReward: 35,
      status: 'active',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestCard(quest: quest, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(QuestCard));
    expect(tapped, isTrue);
  });

  testWidgets('WeeklyQuestCard shows Completed badge when completed',
      (tester) async {
    await tester.pumpWidget(
      _wrap(WeeklyQuestCard(
        quest: _weeklyQuest,
        isCompleted: true,
        onTap: () {},
      )),
    );

    expect(find.text('Sketch the view from a rooftop'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('WeeklyQuestCard hides badge when not completed', (tester) async {
    await tester.pumpWidget(
      _wrap(WeeklyQuestCard(
        quest: _weeklyQuest,
        isCompleted: false,
        onTap: () {},
      )),
    );

    expect(find.text('Completed'), findsNothing);
  });

  testWidgets('ItemCard shows price when not owned', (tester) async {
    const item = AvatarItem(
      id: 'i1',
      name: 'Oak Staff',
      itemType: ItemType.item,
      rarity: 'epic',
      priceCoins: 250,
    );

    await tester.pumpWidget(_wrap(_itemCard(item)));

    expect(find.text('Oak Staff'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
    expect(find.text('Equipped'), findsNothing);
  });

  testWidgets('ItemCard shows Equipped state for equipped item',
      (tester) async {
    const item = AvatarItem(
      id: 'i2',
      name: 'Wizard Hat',
      itemType: ItemType.item,
      rarity: 'rare',
      priceCoins: 120,
      isOwned: true,
      isEquipped: true,
    );

    await tester.pumpWidget(_wrap(_itemCard(item)));

    expect(find.text('Equipped'), findsOneWidget);
    expect(find.text('120'), findsNothing);
  });

  testWidgets('ItemCard shows Owned for owned-but-unequipped item',
      (tester) async {
    const item = AvatarItem(
      id: 'i3',
      name: 'Teddy Bear',
      itemType: ItemType.item,
      rarity: 'common',
      priceCoins: 30,
      isOwned: true,
    );

    await tester.pumpWidget(_wrap(_itemCard(item)));

    expect(find.text('Owned'), findsOneWidget);
    expect(find.text('30'), findsNothing);
  });

  testWidgets('ItemCard disables Buy when unaffordable', (tester) async {
    const item = AvatarItem(
      id: 'i4',
      name: 'Golden Crown',
      itemType: ItemType.item,
      rarity: 'legendary',
      priceCoins: 500,
    );

    await tester.pumpWidget(_wrap(_itemCard(item, canAfford: false)));

    final button = tester.widget<PixelButton>(find.byType(PixelButton));
    expect(button.onPressed, isNull);
  });

  test('NPCEncounter.fromJson parses the /npc/spawn/check offer shape', () {
    // Mirrors the real backend response: {"npc_spawned": true, "offer": {...}}
    // where the offer is a flat NPCQuestOffer row (generated_title etc.).
    final encounter = NPCEncounter.fromJson({
      'npc_spawned': true,
      'offer': {
        'id': 'npc-q1',
        'npc_id': 'npc1',
        'generated_title': 'Deliver a kind word',
        'generated_description': 'Fancy a side quest?',
        'xp_reward': 60,
        'coin_reward': 30,
        'status': 'offered',
        'expires_at': '2026-07-17T12:00:00Z',
      },
    });

    expect(encounter.id, 'npc-q1');
    expect(encounter.message, 'Fancy a side quest?');
    expect(encounter.expiresAt, isNotNull);
    expect(encounter.questOffer?.title, 'Deliver a kind word');
    expect(encounter.questOffer?.source, 'npc');
    expect(encounter.questOffer?.xpReward, 60);
    expect(encounter.questOffer?.npcId, 'npc1');
  });

  test('Achievement.fromJson defaults progress to 1.0 when unlocked', () {
    final a = Achievement.fromJson({
      'id': 'a1',
      'name': 'First Steps',
      'description': 'Complete a quest.',
      'is_unlocked': true,
    });
    expect(a.isUnlocked, isTrue);
    expect(a.progress, 1.0);
  });

  test('Achievement.fromJson clamps progress to 0..1', () {
    final a = Achievement.fromJson({
      'id': 'a2',
      'name': 'Explorer',
      'description': 'Visit places.',
      'progress': 1.5,
    });
    expect(a.progress, 1.0);
    expect(a.isUnlocked, isFalse);
  });

  test('LifeStats.orderedKeys lists known stats first, extras after', () {
    const stats = LifeStats({'fitness': 1, 'social': 2, 'custom': 3});
    expect(stats.orderedKeys, ['social', 'fitness', 'custom']);
  });
}
