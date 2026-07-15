import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../onboarding/providers/onboarding_status_provider.dart';
import '../providers/auth_provider.dart';
import 'auth_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    // Flag the upcoming session as a fresh registration so the router sends
    // it through onboarding (set before the auth state flips — see
    // OnboardingStatusNotifier.expectNewUser).
    OnboardingStatusNotifier.expectNewUser();
    await ref.read(authStateProvider.notifier).register(
          _emailController.text.trim(),
          _displayNameController.text.trim(),
          _passwordController.text,
        );
    if (ref.read(authStateProvider).hasError) {
      OnboardingStatusNotifier.cancelExpectNewUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return AuthShell(
      logoWidth: 190,
      title: 'CREATE ACCOUNT',
      onBack: () => context.go(RouteNames.login),
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid email address',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.nickname],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v != null && v.trim().length >= 2)
                      ? null
                      : 'Choose a name (2+ characters)',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  // The backend requires at least 8 characters.
                  validator: (v) => (v != null && v.length >= 8)
                      ? null
                      : 'Password must be at least 8 characters',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      tooltip:
                          _obscureConfirm ? 'Show password' : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => v == _passwordController.text
                      ? null
                      : 'Passwords do not match',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        PixelButton(
          label: 'Create Account',
          fullWidth: true,
          isLoading: authState.isLoading,
          onPressed: authState.isLoading ? null : _submit,
        ),
        const SizedBox(height: 22),
        const AuthDivider('ALREADY A HERO?'),
        const SizedBox(height: 16),
        PixelButton(
          label: 'Back to Login',
          fullWidth: true,
          variant: PixelButtonVariant.navigation,
          textColor: Colors.black,
          onPressed: () => context.go(RouteNames.login),
        ),
      ],
    );
  }
}
