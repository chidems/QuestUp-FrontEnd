import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../../shared/widgets/pixel_confetti.dart';
import '../providers/onboarding_flow_provider.dart';
import 'adventure_level_screen.dart';
import 'adventurer_reveal_screen.dart';
import 'onboarding_shell.dart';
import 'quiz_question_screen.dart';

/// First-run preferences wizard shown once after registration: a welcome
/// step, a four-question quiz that infers preferred quest types, the
/// adventure level step (difficulty + radius), and the adventurer-profile
/// reveal. Skipping submits the defaults collected so far.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowProvider);
    final notifier = ref.read(onboardingFlowProvider.notifier);
    const revealStep = quizQuestionCount + 2;

    Future<void> finish() async {
      await notifier.submit();
      if (context.mounted) context.go(RouteNames.home);
    }

    final (title, subtitle) = switch (flow.step) {
      0 => (
          'WELCOME TO QUESTUP',
          "Answer four quick questions and we'll match your first quests "
              'to you.'
        ),
      >= 1 && <= quizQuestionCount => (
          'QUESTION ${flow.step} OF $quizQuestionCount',
          quizQuestions[flow.step - 1].prompt
        ),
      const (quizQuestionCount + 1) => ('SET YOUR ADVENTURE LEVEL', null),
      _ => ('YOUR ADVENTURER PROFILE', null),
    };

    final shell = OnboardingShell(
      title: title,
      subtitle: subtitle,
      step: flow.step,
      stepCount: revealStep + 1,
      onBack: flow.step > 0 && !flow.submitting ? notifier.previousStep : null,
      // The reveal is the confirmation — no skip once you're there.
      onSkip: flow.step < revealStep && !flow.submitting ? finish : null,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: switch (flow.step) {
            0 => _WelcomeStep(key: const ValueKey(0), onNext: notifier.nextStep),
            >= 1 && <= quizQuestionCount => QuizQuestionStep(
                key: ValueKey(flow.step),
                index: flow.step - 1,
              ),
            const (quizQuestionCount + 1) =>
              const AdventureLevelStep(key: ValueKey(quizQuestionCount + 1)),
            _ => AdventurerRevealStep(
                key: const ValueKey(revealStep),
                onConfirm: finish,
              ),
          },
        ),
      ],
    );

    // Confetti greets the reveal step, same celebration as level-ups.
    if (flow.step != revealStep) return shell;
    return Stack(
      children: [
        shell,
        const Positioned.fill(
          child: IgnorePointer(child: PixelConfetti(count: 32)),
        ),
      ],
    );
  }
}

/// Step 0: a short landing beat before the quiz starts.
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'No right answers — just pick what sounds most like you.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        PixelButton(label: "Let's go", fullWidth: true, onPressed: onNext),
      ],
    );
  }
}
