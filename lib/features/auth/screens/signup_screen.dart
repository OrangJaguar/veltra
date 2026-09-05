import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Password needs 6+ characters');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on Exception catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('email-already-in-use')) {
      return 'That email is already registered';
    }
    if (message.contains('weak-password')) {
      return 'Password is too weak';
    }
    if (message.contains('invalid-email')) {
      return 'Enter a valid email';
    }
    return 'Could not create account. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text('Create account', style: VeltraTextStyles.title()),
                  const SizedBox(height: 8),
                  Text(
                    'For foremen & supervisors',
                    style: VeltraTextStyles.body(VeltraColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Confirm password'),
                          onSubmitted: (_) => _signUp(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: VeltraTextStyles.caption(VeltraColors.statusRed),
                          ),
                        ],
                        const SizedBox(height: 20),
                        VeltraPrimaryButton(
                          label: 'Sign Up',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _signUp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Already have an account? Log in',
                      style: VeltraTextStyles.body(VeltraColors.safetyOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
