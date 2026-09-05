import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_primary_button.dart';

class VoiceMatchOverlay extends StatelessWidget {
  const VoiceMatchOverlay({
    super.key,
    required this.transcript,
    required this.isListening,
    required this.onPickManually,
    required this.onCancel,
  });

  final String? transcript;
  final bool isListening;
  final VoidCallback onPickManually;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 48,
                    color: VeltraColors.safetyOrange,
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.08, 1.08),
                        duration: 900.ms,
                      ),
                  const SizedBox(height: 16),
                  Text('Say worker name', style: VeltraTextStyles.title()),
                  const SizedBox(height: 8),
                  Text(
                    isListening
                        ? 'Listening for 5 seconds…'
                        : 'Voice unavailable — pick manually',
                    style: VeltraTextStyles.body(VeltraColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  if (transcript != null && transcript!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"$transcript"',
                      style: VeltraTextStyles.headline(VeltraColors.safetyOrange),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  VeltraPrimaryButton(
                    label: 'Pick manually',
                    height: 48,
                    onPressed: onPickManually,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: VeltraTextStyles.body(VeltraColors.textMuted),
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
