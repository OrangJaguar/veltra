import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/utils/body_metrics.dart';
import '../../../core/utils/unit_preferences.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/metric_stat_box.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/scan_record.dart';
import '../../../models/sync_status.dart';
import '../../../models/worker.dart';
import '../../../providers/scan_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/unit_preferences_provider.dart';
import '../../../services/tts_service.dart';
import '../../crew/widgets/trend_chart.dart';
import '../providers/scan_flow_provider.dart';

class ScanResultsScreen extends ConsumerStatefulWidget {
  const ScanResultsScreen({super.key});

  @override
  ConsumerState<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends ConsumerState<ScanResultsScreen> {
  TrendMetric _chartMetric = TrendMetric.skinTemp;
  bool _spoken = false;

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _maybeSpeakResult(Worker worker, String statusLabel) {
    if (_spoken) return;
    if (!ref.read(ttsEnabledProvider)) return;
    _spoken = true;
    ref.read(ttsServiceProvider).speakResult(
          workerName: worker.name,
          statusLabel: statusLabel,
        );
  }

  String _trendArrow(double? current, double? previous) {
    if (current == null || previous == null) return '';
    final diff = current - previous;
    if (diff.abs() < 0.05) return '→';
    return diff > 0 ? '↑' : '↓';
  }

  List<ScanRecord> _chartScans(
    List<ScanRecord> history,
    ScanRecord? current,
  ) {
    if (current == null) return history;
    return [current, ...history.where((s) => s.id != current.id)];
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(scanFlowProvider);
    final worker = flow.worker;
    final result = flow.result;
    final reading = flow.reading;
    final units = ref.watch(unitPreferencesProvider);

    if (worker == null || result == null || reading == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final scansAsync = ref.watch(workerScansProvider(worker.id));
    final previousScan = scansAsync.maybeWhen(
      data: (scans) => scans.isNotEmpty ? scans.first : null,
      orElse: () => null,
    );

    final statusColor = _statusColor(result.status);
    final statusBg = _statusBg(result.status);
    final statusLabel = result.status.label ?? '—';
    _maybeSpeakResult(worker, statusLabel);
    final chartScans = _chartScans(
      scansAsync.valueOrNull ?? [],
      flow.scanRecord,
    );

    return WillPopScope(
      onWillPop: () async {
        ref.read(scanFlowProvider.notifier).reset();
        return true;
      },
      child: Scaffold(
        backgroundColor: VeltraColors.sunriseCream,
        body: SafeArea(
          child: Column(
            children: [
              _ResultsHeader(
                worker: worker,
                statusBg: statusBg,
                statusColor: statusColor,
                statusLabel: statusLabel,
                recommendation: result.recommendation,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Text('Readings', style: VeltraTextStyles.headline()),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.45,
                      children: [
                        MetricStatBox(
                          label: 'Skin temp',
                          value: '${reading.skinTemp.toStringAsFixed(1)} °C',
                          trend: _trendArrow(
                            reading.skinTemp,
                            previousScan?.skinTemp,
                          ),
                          icon: Icons.thermostat_rounded,
                        ),
                        MetricStatBox(
                          label: 'Sweat rate',
                          value: '${reading.sweatRate.toStringAsFixed(2)} L/hr',
                          trend: _trendArrow(
                            reading.sweatRate,
                            previousScan?.sweatRate,
                          ),
                          icon: Icons.water_drop_outlined,
                        ),
                        MetricStatBox(
                          label: 'Salinity',
                          value: '${reading.salinity.toStringAsFixed(0)} mmol/L',
                          trend: _trendArrow(
                            reading.salinity,
                            previousScan?.salinity,
                          ),
                          icon: Icons.science_outlined,
                        ),
                        MetricStatBox(
                          label: 'Z-score',
                          value: flow.zScore?.toStringAsFixed(2) ?? '—',
                          trend: _trendArrow(
                            flow.zScore,
                            previousScan?.zScore,
                          ),
                          icon: Icons.analytics_outlined,
                          accentColor: VeltraColors.skyWorkBlue,
                        ),
                        MetricStatBox(
                          label: 'Temp rate',
                          value:
                              '${flow.tempRate?.toStringAsFixed(2) ?? '—'} °C/hr',
                          icon: Icons.trending_up_rounded,
                        ),
                        MetricStatBox(
                          label: 'WBGT',
                          value: '${flow.wbgt?.toStringAsFixed(1) ?? '—'} °C',
                          icon: Icons.wb_sunny_outlined,
                          accentColor: VeltraColors.skyWorkBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ProfileStatsSection(worker: worker, units: units),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Trend', style: VeltraTextStyles.headline()),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VeltraColors.glassBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TrendMetric>(
                              value: _chartMetric,
                              isDense: true,
                              style: VeltraTextStyles.body(),
                              items: TrendMetric.values
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _chartMetric = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TrendChart(
                      scans: chartScans.take(10).toList().reversed.toList(),
                      metric: _chartMetric,
                      highlightLatest: true,
                    ),
                    if (flow.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        flow.error!,
                        style: VeltraTextStyles.caption(VeltraColors.statusRed),
                      ),
                    ],
                  ],
                ),
              ),
              _ResultsFooter(
                isSaving: flow.step == ScanFlowStep.saving,
                showAlert: result.status == WorkerStatus.red,
                workerName: worker.name,
                recommendation: result.recommendation,
                onSave: () => ref
                    .read(scanFlowProvider.notifier)
                    .saveAndReset()
                    .then((_) {
                  if (context.mounted) context.pop();
                }),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 280.ms)
          .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Color _statusColor(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.green:
        return VeltraColors.statusGreen;
      case WorkerStatus.amber:
        return VeltraColors.statusAmber;
      case WorkerStatus.red:
        return VeltraColors.statusRed;
      case WorkerStatus.none:
        return VeltraColors.textMuted;
    }
  }

  Color _statusBg(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.green:
        return VeltraColors.statusGreenBg;
      case WorkerStatus.amber:
        return VeltraColors.statusAmberBg;
      case WorkerStatus.red:
        return VeltraColors.statusRedBg;
      case WorkerStatus.none:
        return VeltraColors.warmSand;
    }
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.worker,
    required this.statusBg,
    required this.statusColor,
    required this.statusLabel,
    required this.recommendation,
  });

  final Worker worker;
  final Color statusBg;
  final Color statusColor;
  final String statusLabel;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 3),
            ),
            child: WorkerAvatar(
              name: worker.name,
              photoPath: worker.photoPath,
              radius: 40,
            ),
          ),
          const SizedBox(height: 10),
          Text(statusLabel, style: VeltraTextStyles.display(statusColor)),
          const SizedBox(height: 6),
          Text(worker.name, style: VeltraTextStyles.title()),
          const SizedBox(height: 6),
          Text(
            recommendation,
            style: VeltraTextStyles.body(VeltraColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileStatsSection extends StatelessWidget {
  const _ProfileStatsSection({
    required this.worker,
    required this.units,
  });

  final Worker worker;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Worker profile', style: VeltraTextStyles.headline()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (worker.employeeId != null && worker.employeeId!.isNotEmpty)
                _ProfileChip(
                  icon: Icons.badge_outlined,
                  label: 'ID ${worker.employeeId}',
                ),
              if (worker.nfcId != null && worker.nfcId!.isNotEmpty)
                _ProfileChip(
                  icon: Icons.nfc_rounded,
                  label: 'NFC ${worker.nfcId}',
                ),
              if (worker.age != null)
                _ProfileChip(
                  icon: Icons.cake_outlined,
                  label: '${worker.age} yrs',
                ),
              if (worker.heightCm != null)
                _ProfileChip(
                  icon: Icons.height_rounded,
                  label: BodyMetrics.formatHeightCm(
                    worker.heightCm,
                    useImperial: units.heightUnit == MeasureUnit.imperial,
                  ),
                ),
              if (worker.weightKg != null)
                _ProfileChip(
                  icon: Icons.monitor_weight_outlined,
                  label: BodyMetrics.formatWeightKg(
                    worker.weightKg,
                    useImperial: units.weightUnit == MeasureUnit.imperial,
                  ),
                ),
              if (worker.bmi != null)
                _ProfileChip(
                  icon: Icons.favorite_outline,
                  label: 'BMI ${BodyMetrics.formatBmi(worker.bmi)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: VeltraColors.warmSand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: VeltraColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: VeltraTextStyles.caption()),
        ],
      ),
    );
  }
}

class _ResultsFooter extends StatelessWidget {
  const _ResultsFooter({
    required this.isSaving,
    required this.showAlert,
    required this.workerName,
    required this.recommendation,
    required this.onSave,
  });

  final bool isSaving;
  final bool showAlert;
  final String workerName;
  final String recommendation;
  final VoidCallback onSave;

  Future<void> _shareAlert() async {
    final timestamp = DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());
    await Share.share(
      'Veltra Alert — $workerName — RED — $recommendation — $timestamp',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: VeltraColors.sunriseCream,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VeltraPrimaryButton(
            label: isSaving ? 'Saving…' : 'Log & Next',
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
          ),
          if (showAlert) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _shareAlert,
              style: OutlinedButton.styleFrom(
                foregroundColor: VeltraColors.statusRed,
                side: const BorderSide(color: VeltraColors.statusRed),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Alert',
                style: VeltraTextStyles.body(VeltraColors.statusRed)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
