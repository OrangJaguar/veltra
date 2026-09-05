import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../auth/providers/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _crewController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _crewController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final crewName = _crewController.text.trim();
    if (crewName.isEmpty) {
      setState(() => _error = 'Enter a crew name');
      return;
    }

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(userRepositoryProvider).completeOnboarding(
            uid: user.uid,
            email: user.email ?? '',
            crewName: crewName,
          );
      if (mounted) context.go('/scan');
    } on Exception {
      setState(() => _error = 'Could not save crew. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'Name your crew',
                  style: VeltraTextStyles.title(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You can add workers next',
                  style: VeltraTextStyles.body(VeltraColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _crewController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Crew name',
                          hintText: 'Roof Crew A',
                        ),
                        onSubmitted: (_) => _complete(),
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
                        label: 'Get Started',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _complete,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
