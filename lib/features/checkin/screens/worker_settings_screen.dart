import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_outlined_button.dart';
import '../../../models/check_in.dart';
import '../../../models/worker.dart';
import '../checkin_labels.dart';
import '../providers/demo_session_provider.dart';

class WorkerSettingsPage extends ConsumerWidget {
  const WorkerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(selectedWorkerProvider).valueOrNull;
    final window = ref.watch(latestWindowProvider).valueOrNull;
    final source = ref.watch(demoSessionProvider).valueOrNull?.scanSource ??
        CheckInSources.simulated;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text('Settings', style: VeltraTextStyles.title()),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Worker', style: VeltraTextStyles.caption()),
              const SizedBox(height: 6),
              Text(worker?.name ?? 'Worker', style: VeltraTextStyles.headline()),
              const SizedBox(height: 12),
              VeltraOutlinedButton(
                label: 'Switch worker',
                onPressed: worker == null
                    ? null
                    : () => _switchWorker(context, ref, worker),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan source', style: VeltraTextStyles.caption()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SourceChip(
                    label: 'Simulated',
                    selected: source == CheckInSources.simulated,
                    onTap: () => _setSource(ref, CheckInSources.simulated),
                  ),
                  _SourceChip(
                    label: 'Physical test tag',
                    selected: source == CheckInSources.nfcTestTag,
                    onTap: () => _setSource(ref, CheckInSources.nfcTestTag),
                  ),
                  _SourceChip(
                    label: 'Sensor pod',
                    selected: source == CheckInSources.sensorPod,
                    onTap: () => _setSource(ref, CheckInSources.sensorPod),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Window', style: VeltraTextStyles.caption()),
              const SizedBox(height: 6),
              Text(
                windowLabel(window),
                style: VeltraTextStyles.headline(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _setSource(WidgetRef ref, String source) async {
    await ref.read(demoSessionProvider.notifier).saveConfig(
          (current) => current.copyWith(scanSource: source),
        );
  }

  Future<void> _switchWorker(
    BuildContext context,
    WidgetRef ref,
    Worker current,
  ) async {
    final workers = await ref.read(activeCrewWorkersProvider.future);
    if (!context.mounted) return;

    final picked = await showModalBottomSheet<Worker>(
      context: context,
      backgroundColor: VeltraColors.sunriseCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Choose worker', style: VeltraTextStyles.headline()),
              for (final worker in workers)
                ListTile(
                  title: Text(worker.name, style: VeltraTextStyles.headline()),
                  trailing: worker.id == current.id
                      ? const Icon(Icons.check_rounded, color: VeltraColors.safetyOrange)
                      : null,
                  onTap: () => Navigator.pop(context, worker),
                ),
            ],
          ),
        );
      },
    );

    if (picked == null || picked.id == current.id || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Check in as ${picked.name}?',
            style: VeltraTextStyles.headline(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(demoSessionProvider.notifier).setWorker(picked.id);
    }
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? VeltraColors.safetyOrange : VeltraColors.glassWhite,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            label,
            style: VeltraTextStyles.label(
              selected ? VeltraColors.textOnOrange : VeltraColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
