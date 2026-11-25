import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_outlined_button.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../providers/worker_providers.dart';
import '../checkin_labels.dart';
import '../providers/demo_session_provider.dart';

class SupervisorSettingsPage extends ConsumerWidget {
  const SupervisorSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crew = ref.watch(checkInCrewProvider).valueOrNull;
    final window = ref.watch(latestWindowProvider).valueOrNull;
    final open = ref.watch(openCheckInWindowProvider).valueOrNull;
    final site = crew?.siteLabel;
    final siteLabel = site == null || site.trim().isEmpty ? 'No site' : site;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text('Settings', style: VeltraTextStyles.title()),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Window', style: VeltraTextStyles.caption()),
              const SizedBox(height: 6),
              Text(windowLabel(window), style: VeltraTextStyles.headline()),
              const SizedBox(height: 12),
              VeltraPrimaryButton(
                label: 'Open window',
                onPressed: crew == null ? null : () => _open(context, ref, crew.id),
              ),
              const SizedBox(height: 8),
              VeltraOutlinedButton(
                label: 'Close window',
                onPressed: open == null ? null : () => _close(ref, open.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Crew', style: VeltraTextStyles.caption()),
              const SizedBox(height: 6),
              Text(crew?.name ?? 'No crew', style: VeltraTextStyles.headline()),
              const SizedBox(height: 4),
              Text(siteLabel, style: VeltraTextStyles.body(VeltraColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, String crewId) async {
    final result = await ref.read(checkInRepositoryProvider).openWindow(crewId);
    bumpCheckIns(ref);
    if (result.created || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A window is already open')),
    );
  }

  Future<void> _close(WidgetRef ref, String windowId) async {
    await ref.read(checkInRepositoryProvider).closeWindow(windowId);
    bumpCheckIns(ref);
  }
}
