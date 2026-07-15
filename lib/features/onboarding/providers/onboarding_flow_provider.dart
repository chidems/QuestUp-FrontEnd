import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/quest_constants.dart';
import '../../profile/models/profile_models.dart';
import '../../profile/providers/profile_provider.dart';
import '../../settings/providers/settings_provider.dart';
import 'onboarding_status_provider.dart';

/// Number of quiz questions used to infer preferred quest types.
const quizQuestionCount = 4;

/// In-memory wizard state. Not persisted mid-flow on purpose: if the app is
/// killed during onboarding the pending flag is still set, so restarting
/// simply re-shows the wizard from the top.
class OnboardingFlowState {
  /// 0 = welcome, 1-4 = quiz questions, 5 = adventure level, 6 = reveal.
  final int step;

  /// Quest type chosen per quiz question (null = not answered yet).
  final List<String?> answers;

  final int difficulty; // 1-5
  final double radiusKm;
  final bool submitting;

  const OnboardingFlowState({
    this.step = 0,
    this.answers = const [null, null, null, null],
    this.difficulty = 3,
    this.radiusKm = 2.0,
    this.submitting = false,
  });

  /// Quest types inferred from the quiz: any type picked in at least two
  /// answers qualifies. Falls back to all three (the backend default) when
  /// nothing reaches that bar — e.g. the user skipped early.
  Set<String> get questTypes {
    final counts = <String, int>{};
    for (final answer in answers) {
      if (answer != null) counts[answer] = (counts[answer] ?? 0) + 1;
    }
    final picked = {
      for (final entry in counts.entries)
        if (entry.value >= 2) entry.key,
    };
    if (picked.isEmpty) {
      return const {QuestType.location, QuestType.social, QuestType.action};
    }
    return picked;
  }

  OnboardingFlowState copyWith({
    int? step,
    List<String?>? answers,
    int? difficulty,
    double? radiusKm,
    bool? submitting,
  }) =>
      OnboardingFlowState(
        step: step ?? this.step,
        answers: answers ?? this.answers,
        difficulty: difficulty ?? this.difficulty,
        radiusKm: radiusKm ?? this.radiusKm,
        submitting: submitting ?? this.submitting,
      );
}

class OnboardingFlowNotifier extends Notifier<OnboardingFlowState> {
  @override
  OnboardingFlowState build() => const OnboardingFlowState();

  /// Records the answer for one quiz question and advances to the next step.
  void answerQuestion(int index, String questType) {
    final next = [...state.answers];
    next[index] = questType;
    state = state.copyWith(answers: next, step: state.step + 1);
  }

  void setDifficulty(int value) => state = state.copyWith(difficulty: value);

  void setRadius(double km) => state = state.copyWith(radiusKm: km);

  void nextStep() => state = state.copyWith(step: state.step + 1);

  void previousStep() =>
      state = state.copyWith(step: state.step > 0 ? state.step - 1 : 0);

  /// Persists the collected preferences: one PUT /profile with everything,
  /// mirrored into the local Settings prefs (radius + categories) so the
  /// Settings screen reflects the same choices, then marks onboarding done.
  /// Used by both the final "Start Questing" CTA and "Skip for now".
  Future<void> submit() async {
    if (state.submitting) return;
    state = state.copyWith(submitting: true);
    try {
      final questTypes = state.questTypes;
      await ref.read(profileRepositoryProvider).updateProfile(UserProfile(
            preferredRadiusKm: state.radiusKm,
            preferredDifficulty: state.difficulty,
            preferredQuestTypes: questTypes.toList(),
          ));
      final settings = ref.read(settingsProvider.notifier);
      await settings.setRadius(state.radiusKm);
      await settings.setCategories(questTypes);
      await ref.read(onboardingPendingProvider.notifier).markCompleted();
    } finally {
      state = state.copyWith(submitting: false);
    }
  }
}

final onboardingFlowProvider =
    NotifierProvider<OnboardingFlowNotifier, OnboardingFlowState>(
  OnboardingFlowNotifier.new,
);
