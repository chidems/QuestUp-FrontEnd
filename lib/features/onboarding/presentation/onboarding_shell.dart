import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';

/// Chrome for the onboarding wizard: the splash/auth dark gradient backdrop,
/// a pixel-font step headline, progress squares, optional back arrow and
/// "Skip for now" link, and a keyboard-safe centered scroll column.
///
/// Like the auth screens, always renders dark so register → onboarding →
/// app reads as one continuous sequence.
class OnboardingShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int step;
  final int stepCount;
  final List<Widget> children;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const OnboardingShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.step,
    this.stepCount = 3,
    required this.children,
    this.onBack,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Builder(builder: (context) {
          final palette = context.colors;
          return Scaffold(
            backgroundColor: palette.surfaceDeep,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF16182C),
                    Color(0xFF1E2138),
                    Color(0xFF0C0E1E),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _topBar(context),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _StepDots(
                                            step: step, count: stepCount),
                                        const SizedBox(height: 24),
                                        Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                        if (subtitle case final sub?) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            sub,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                        const SizedBox(height: 28),
                                        ...children,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final palette = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (onBack case final back?)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: palette.textPrimary,
                tooltip: 'Back',
                onPressed: back,
              )
            else
              const SizedBox(width: 48),
            const Spacer(),
            if (onSkip case final skip?)
              TextButton(
                onPressed: skip,
                child: const Text('Skip for now'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pixel progress indicator: one chunky square per step.
class _StepDots extends StatelessWidget {
  final int step;
  final int count;

  const _StepDots({required this.step, required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == step ? 12 : 9,
            height: i == step ? 12 : 9,
            decoration: BoxDecoration(
              color: i <= step ? palette.primaryLight : palette.surfaceVariant,
              border: Border.all(
                color: i <= step ? palette.primaryLight : palette.border,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
