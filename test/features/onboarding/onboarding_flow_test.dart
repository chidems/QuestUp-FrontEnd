import 'package:flutter_test/flutter_test.dart';
import 'package:quest_up/core/constants/quest_constants.dart';
import 'package:quest_up/features/onboarding/providers/onboarding_flow_provider.dart';

void main() {
  group('OnboardingFlowState.questTypes', () {
    test('type answered twice or more is included', () {
      const state = OnboardingFlowState(answers: [
        QuestType.location,
        QuestType.location,
        QuestType.social,
        QuestType.action,
      ]);
      expect(state.questTypes, {QuestType.location});
    });

    test('two types with two answers each are both included', () {
      const state = OnboardingFlowState(answers: [
        QuestType.social,
        QuestType.action,
        QuestType.social,
        QuestType.action,
      ]);
      expect(state.questTypes, {QuestType.social, QuestType.action});
    });

    test('no answers falls back to all three types', () {
      const state = OnboardingFlowState();
      expect(
        state.questTypes,
        {QuestType.location, QuestType.social, QuestType.action},
      );
    });

    test('partial answers with no type reaching two fall back to all three',
        () {
      const state = OnboardingFlowState(answers: [
        QuestType.location,
        QuestType.social,
        null,
        null,
      ]);
      expect(
        state.questTypes,
        {QuestType.location, QuestType.social, QuestType.action},
      );
    });
  });
}
