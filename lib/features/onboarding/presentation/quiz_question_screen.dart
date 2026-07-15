import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/quest_constants.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../providers/onboarding_flow_provider.dart';

/// One quiz answer: display copy plus the quest type it scores toward.
/// The mapping is invisible to the user — they just take a short quiz.
class QuizOption {
  final String emoji;
  final String label;
  final String questType;

  const QuizOption(this.emoji, this.label, this.questType);
}

class QuizQuestion {
  final String prompt;
  final List<QuizOption> options;

  const QuizQuestion(this.prompt, this.options);
}

/// The four questions that infer preferred quest types. Each answer scores
/// one point for its type; types with 2+ points become the preference.
const quizQuestions = [
  QuizQuestion(
    "It's a free Saturday afternoon. What sounds best?",
    [
      QuizOption('📍', "Checking out a part of town I've never been to",
          QuestType.location),
      QuizOption('💬', 'Meeting up with friends — or meeting someone new',
          QuestType.social),
      QuizOption('🏃', 'Getting moving — a run, a workout, a long walk',
          QuestType.action),
    ],
  ),
  QuizQuestion(
    'Your camera roll is mostly...',
    [
      QuizOption('🌇', 'Places — streets, cafés, views I stumbled onto',
          QuestType.location),
      QuizOption('🎉', 'People — group photos, dinners, nights out',
          QuestType.social),
      QuizOption('⛰️', 'Activity — trails, gyms, post-workout selfies',
          QuestType.action),
    ],
  ),
  QuizQuestion(
    "You're planning the perfect day off in a new city. "
    'First thing on the list?',
    [
      QuizOption('🗺️', 'Wander with no fixed plan and see what I find',
          QuestType.location),
      QuizOption('🍽️', 'Find where the locals hang out and join in',
          QuestType.social),
      QuizOption('🚴', 'Book something active — bike tour, climbing, kayaking',
          QuestType.action),
    ],
  ),
  QuizQuestion(
    'Your friends would describe you as...',
    [
      QuizOption('🔎', 'The one who always knows a cool new spot',
          QuestType.location),
      QuizOption('📣', 'The one who gets everyone together', QuestType.social),
      QuizOption('⚡', "The one who's always up for doing something",
          QuestType.action),
    ],
  ),
];

/// Steps 1-4: one quiz question with three tappable answer cards. Tapping an
/// answer records it and advances; navigating back shows the saved answer.
class QuizQuestionStep extends ConsumerWidget {
  final int index;

  const QuizQuestionStep({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowProvider);
    final question = quizQuestions[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in question.options) ...[
          _OptionCard(
            option: option,
            selected: flow.answers[index] == option.questType,
            onTap: () => ref
                .read(onboardingFlowProvider.notifier)
                .answerQuestion(index, option.questType),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final QuizOption option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      child: PixelBox(
        onTap: onTap,
        highlightColor: selected ? palette.primaryLight : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
