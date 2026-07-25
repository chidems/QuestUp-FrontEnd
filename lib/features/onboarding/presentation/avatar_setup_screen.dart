import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../avatar/models/avatar_models.dart';
import '../../avatar/presentation/avatar_preview.dart';
import '../../avatar/presentation/customize_screen.dart';
import '../../avatar/providers/avatar_provider.dart';
import '../providers/onboarding_flow_provider.dart';

/// Step between the adventure level picker and the reveal: a chance to
/// personalize the hero's look before it's shown off. Customizing (or
/// skipping) both advance the wizard — this step is never a dead end.
class AvatarSetupStep extends ConsumerWidget {
  const AvatarSetupStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingFlowProvider.notifier);
    final appearance =
        ref.watch(appearanceProvider).value ?? AvatarAppearance.defaults;

    // A plain Navigator push (not go_router's context.push) so the app
    // router's "onboarding still pending" redirect — which would otherwise
    // bounce any non-onboarding route straight back here — never fires.
    Future<void> customize() async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CustomizeScreen()),
      );
      notifier.nextStep();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 160,
            child: AvatarPreview(appearance: appearance),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "This is your hero. Give them a look of your own, or dive in "
          'and change it anytime later.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        PixelButton(
          label: 'Customize My Hero',
          fullWidth: true,
          onPressed: customize,
        ),
        const SizedBox(height: 12),
        PixelButton(
          label: 'Skip for now',
          fullWidth: true,
          variant: PixelButtonVariant.navigation,
          textColor: Colors.black,
          onPressed: notifier.nextStep,
        ),
      ],
    );
  }
}
