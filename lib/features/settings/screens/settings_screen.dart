import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/demo_mode.dart';
import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../models/sync_status.dart';
import '../../../providers/dev_settings_provider.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/worker_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../scan/providers/scan_flow_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loadingDemo = false;
  bool _endingShift = false;

  Future<void> _logout() async {
    if (ref.read(demoModeProvider)) {
      ref.read(demoModeProvider.notifier).state = false;
    } else {
      await ref.read(authRepositoryProvider).signOut();
    }
    if (mounted) context.go('/login');
  }

  Future<void> _loadDemoCrew() async {
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;

    setState(() => _loadingDemo = true);
    try {
      final demoService = ref.read(demoDataServiceProvider);
      await demoService.seedDemoCrew(userId);
      refreshWorkers(ref);
      try {
        await syncNow(ref);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demo crew added',
              style: VeltraTextStyles.body(VeltraColors.textOnOrange),
            ),
            backgroundColor: VeltraColors.safetyOrange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDemo = false);
    }
  }

  Future<void> _endShift() async {
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;

    setState(() => _endingShift = true);
    try {
      await ref.read(shiftServiceProvider).endShift(userId);
      ref.invalidate(shiftStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Shift ended',
              style: VeltraTextStyles.body(VeltraColors.textOnOrange),
            ),
            backgroundColor: VeltraColors.safetyOrange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _endingShift = false);
    }
  }

  String _formatLastSync(DateTime? time) {
    if (time == null) return 'Never synced';
    return DateFormat('MMM d, h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncBootstrapProvider);
    final isDemo = ref.watch(demoModeProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final accountLabel = isDemo
        ? 'Demo foreman (offline)'
        : (user?.email ?? '—');
    final crewLabel = isDemo ? 'Demo Construction Co.' : profile?.crewName;
    final syncStatus = ref.watch(syncStatusProvider).valueOrNull ?? SyncStatus.offline;
    final workersAsync = ref.watch(workersListProvider);
    final shiftAsync = ref.watch(shiftStatusProvider);
    final lastSyncAsync = ref.watch(lastSyncTimeProvider);
    final versionAsync = ref.watch(appVersionProvider);
    final ttsEnabled = ref.watch(ttsEnabledProvider);
    final devExpanded = ref.watch(devSectionExpandedProvider);

    final syncLabel = switch (syncStatus) {
      SyncStatus.synced => 'Sync · up to date',
      SyncStatus.pending => 'Sync · pending upload',
      SyncStatus.offline => 'Sync · offline',
    };

    final syncColor = switch (syncStatus) {
      SyncStatus.synced => VeltraColors.statusGreen,
      SyncStatus.pending => VeltraColors.coneAmber,
      SyncStatus.offline => VeltraColors.textMuted,
    };

    final shiftStartLabel = shiftAsync.maybeWhen(
      data: (shift) {
        if (shift.startedAt == null) return 'Starts on first scan today';
        return DateFormat('h:mm a').format(shift.startedAt!);
      },
      orElse: () => 'Loading…',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: ListView(
        children: [
          Text('Settings', style: VeltraTextStyles.title()),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                _SettingsRow(
                  icon: Icons.email_outlined,
                  label: accountLabel,
                ),
                if (crewLabel != null) ...[
                  const SizedBox(height: 8),
                  _SettingsRow(
                    icon: Icons.groups_outlined,
                    label: crewLabel,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crew', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                workersAsync.when(
                  data: (workers) => Text(
                    '${workers.length} workers on this device',
                    style: VeltraTextStyles.body(VeltraColors.textSecondary),
                  ),
                  loading: () => Text(
                    'Loading workers…',
                    style: VeltraTextStyles.caption(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/crew'),
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text('Manage crew'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VeltraColors.safetyOrange,
                    side: const BorderSide(color: VeltraColors.safetyOrange),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                VeltraPrimaryButton(
                  label: _loadingDemo ? 'Adding…' : 'Load demo crew',
                  height: 44,
                  isLoading: _loadingDemo,
                  onPressed: _loadingDemo ? null : _loadDemoCrew,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                _SettingsRow(
                  icon: Icons.schedule_outlined,
                  label: 'Started · $shiftStartLabel',
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _endingShift ? null : _endShift,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VeltraColors.textSecondary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_endingShift ? 'Ending…' : 'End shift'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => ref
                      .read(devSectionExpandedProvider.notifier)
                      .state = !devExpanded,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Developer', style: VeltraTextStyles.headline()),
                        ),
                        Icon(
                          devExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: VeltraColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (devExpanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Force mock scan readings for demos',
                    style: VeltraTextStyles.caption(),
                  ),
                  const SizedBox(height: 12),
                  ...MockScanPreset.values.map((preset) {
                    final selected = ref.watch(mockScanPresetProvider) == preset;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => ref
                            .read(mockScanPresetProvider.notifier)
                            .setPreset(preset),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? VeltraColors.safetyOrange
                                    : VeltraColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _presetLabel(preset),
                                style: VeltraTextStyles.body(
                                  selected
                                      ? VeltraColors.textPrimary
                                      : VeltraColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Voice confirmation (TTS)',
                      style: VeltraTextStyles.body(),
                    ),
                    subtitle: Text(
                      'Speak result after each scan',
                      style: VeltraTextStyles.caption(),
                    ),
                    value: ttsEnabled,
                    activeColor: VeltraColors.safetyOrange,
                    onChanged: (value) => ref
                        .read(ttsEnabledProvider.notifier)
                        .setEnabled(value),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync & about', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                _SettingsRow(
                  icon: Icons.cloud_outlined,
                  label: syncLabel,
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: syncColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SettingsRow(
                  icon: Icons.sync_rounded,
                  label: lastSyncAsync.when(
                    data: _formatLastSync,
                    loading: () => 'Last sync · …',
                    error: (_, __) => 'Last sync · unknown',
                  ),
                ),
                const SizedBox(height: 8),
                _SettingsRow(
                  icon: Icons.info_outline,
                  label: versionAsync.when(
                    data: (version) => 'Version $version',
                    loading: () => 'Version …',
                    error: (_, __) => 'Version 1.0.0',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/settings/privacy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VeltraColors.safetyOrange,
                    side: const BorderSide(color: VeltraColors.safetyOrange),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Privacy policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          VeltraPrimaryButton(
            label: 'Log Out',
            height: 52,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  String _presetLabel(MockScanPreset preset) {
    switch (preset) {
      case MockScanPreset.random:
        return 'Random readings';
      case MockScanPreset.forceGreen:
        return 'Force GREEN';
      case MockScanPreset.forceAmber:
        return 'Force AMBER';
      case MockScanPreset.forceRed:
        return 'Force RED';
    }
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: VeltraColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: VeltraTextStyles.body(VeltraColors.textSecondary),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
