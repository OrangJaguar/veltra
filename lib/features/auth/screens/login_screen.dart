import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../core/demo_mode.dart';
import '../../../providers/worker_providers.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterDemo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ref.read(demoModeProvider.notifier).state = true;
      final workers = await ref.read(workerRepositoryProvider).getWorkers(demoUserId);
      if (workers.isEmpty) {
        await ref.read(demoDataServiceProvider).seedDemoCrew(demoUserId);
      }
      refreshWorkers(ref);
      if (mounted) context.go('/scan');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
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
    if (message.contains('user-not-found') || message.contains('wrong-password')) {
      return 'Wrong email or password';
    }
    if (message.contains('invalid-email')) {
      return 'Enter a valid email';
    }
    if (message.contains('network')) {
      return 'Check your connection';
    }
    return 'Could not sign in. Try again.';
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: VeltraColors.hardHatYellow,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: VeltraColors.safetyOrange.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      size: 36,
                      color: VeltraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Veltra', style: VeltraTextStyles.display()),
                  const SizedBox(height: 8),
                  Text(
                    'Heat safety for your crew',
                    style: VeltraTextStyles.body(VeltraColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          onSubmitted: (_) => _login(),
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
                          label: 'Log In',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _login,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  VeltraPrimaryButton(
                    label: 'Quick Demo — skip sign in',
                    height: 48,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _enterDemo,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: Text(
                      'New here? Create account',
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
