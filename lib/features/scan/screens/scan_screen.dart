import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/worker.dart';
import '../../../providers/worker_providers.dart';
import '../providers/scan_flow_provider.dart';
import '../widgets/manual_scan_sheet.dart';
import '../widgets/voice_match_overlay.dart';
import '../widgets/worker_picker_sheet.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  Future<void> _openWorkerPicker(BuildContext context, WidgetRef ref) async {
    ref.read(scanFlowProvider.notifier).cancelVoiceMatch();
    final workers = await ref.read(workersListProvider.future);
    if (!context.mounted || workers.isEmpty) return;

    final worker = await showModalBottomSheet<Worker>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkerPickerSheet(workers: workers),
    );

    if (worker != null && context.mounted) {
      await ref.read(scanFlowProvider.notifier).selectWorker(worker);
    }
  }

  Future<void> _openManualEntry(BuildContext context, WidgetRef ref) async {
    final workers = await ref.read(workersListProvider.future);
    if (!context.mounted) return;
    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add workers in Crew before manual entry',
            style: VeltraTextStyles.body(VeltraColors.textOnOrange),
          ),
          backgroundColor: VeltraColors.safetyOrange,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualScanSheet(workers: workers),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(scanFlowProvider, (previous, next) {
      if (next.step == ScanFlowStep.results &&
          previous?.step != ScanFlowStep.results) {
        context.push('/scan/results');
      }
    });

    final flow = ref.watch(scanFlowProvider);
    final shiftAsync = ref.watch(shiftStatusProvider);
    final weatherAsync = ref.watch(weatherReadingProvider);

    final shiftLabel = shiftAsync.maybeWhen(
      data: (shift) => shift.chipLabel,
      orElse: () => 'Shift · …',
    );
    final weatherLabel = weatherAsync.maybeWhen(
      data: (reading) =>
          '${reading.airTempC.toStringAsFixed(0)}°C · WBGT ${reading.wbgt.toStringAsFixed(1)}',
      orElse: () => 'Weather · …',
    );

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            children: [
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: shiftLabel,
                  ),
                  const Spacer(),
                  _InfoChip(
                    icon: Icons.wb_sunny_rounded,
                    label: weatherLabel,
                    color: VeltraColors.skyWorkBlue,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
              if (flow.error != null) ...[
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    flow.error!,
                    style: VeltraTextStyles.caption(VeltraColors.statusRed),
                  ),
                ),
              ],
              const Spacer(),
              _ScanButton(
                isLoading: flow.step == ScanFlowStep.scanning,
                onPressed: flow.isBusy ? null : () => ref.read(scanFlowProvider.notifier).startScan(),
              ),
              const SizedBox(height: 14),
              Text(
                'Tap to read sensors',
                style: VeltraTextStyles.body(VeltraColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: flow.isBusy
                    ? null
                    : () => _openManualEntry(context, ref),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  'Manual entry',
                  style: VeltraTextStyles.body(VeltraColors.textMuted),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
        if (flow.step == ScanFlowStep.voiceMatch)
          VoiceMatchOverlay(
            transcript: flow.voiceTranscript,
            isListening: flow.voiceListening,
            onPickManually: () => _openWorkerPicker(context, ref),
            onCancel: () => ref.read(scanFlowProvider.notifier).reset(),
          ),
        if (flow.step == ScanFlowStep.computing)
          const _ComputingOverlay(),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VeltraColors.safetyOrange,
      borderRadius: BorderRadius.circular(999),
      elevation: 8,
      shadowColor: VeltraColors.safetyOrange.withOpacity(0.35),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 220,
          height: 220,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: VeltraColors.textOnOrange,
                    strokeWidth: 3,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sensors_rounded,
                      size: 52,
                      color: VeltraColors.textOnOrange,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Scan Hard Hat',
                      style: VeltraTextStyles.headline(VeltraColors.textOnOrange),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          duration: 1800.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _ComputingOverlay extends StatelessWidget {
  const _ComputingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: VeltraColors.safetyOrange),
            const SizedBox(height: 16),
            Text('Computing risk…', style: VeltraTextStyles.headline()),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = VeltraColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: VeltraTextStyles.caption(color)),
        ],
      ),
    );
  }
}
