import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/utils/body_metrics.dart';
import '../../../core/utils/unit_preferences.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/sync_status.dart';
import '../../../models/worker.dart';
import '../../../providers/scan_providers.dart';
import '../../../providers/unit_preferences_provider.dart';
import '../../../providers/worker_providers.dart';
import '../widgets/scan_history_list.dart';
import '../widgets/trend_chart.dart';

class WorkerDetailScreen extends ConsumerStatefulWidget {
  const WorkerDetailScreen({super.key, required this.workerId});

  final String workerId;

  @override
  ConsumerState<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends ConsumerState<WorkerDetailScreen> {
  TrendMetric _chartMetric = TrendMetric.skinTemp;

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitPreferencesProvider);
    final scansAsync = ref.watch(workerScansProvider(widget.workerId));

    return FutureBuilder<Worker?>(
      future: ref.read(workerRepositoryProvider).getWorker(widget.workerId),
      builder: (context, snapshot) {
        final worker = snapshot.data;

        return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: VeltraColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        worker?.name ?? 'Worker',
                        style: VeltraTextStyles.title(),
                      ),
                    ),
                    if (worker != null)
                      IconButton(
                        onPressed: () =>
                            context.push('/crew/${worker.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        color: VeltraColors.safetyOrange,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: VeltraColors.safetyOrange,
                        ),
                      )
                    : worker == null
                        ? Center(
                            child: Text(
                              'Worker not found',
                              style: VeltraTextStyles.body(
                                VeltraColors.statusRed,
                              ),
                            ),
                          )
                        : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: [
                          GlassCard(
                            child: Column(
                              children: [
                                WorkerAvatar(
                                  name: worker.name,
                                  photoPath: worker.photoPath,
                                  radius: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  worker.name,
                                  style: VeltraTextStyles.title(),
                                ),
                                if (worker.lastStatus?.label != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusBg(worker.lastStatus!)
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Last scan: ${worker.lastStatus!.label}',
                                      style: VeltraTextStyles.label(
                                        _statusColor(worker.lastStatus!),
                                      ),
                                    ),
                                  ),
                                ],
                                if (worker.lastScanAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('MMM d, h:mm a')
                                        .format(worker.lastScanAt!),
                                    style: VeltraTextStyles.caption(),
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
                                Text('Profile', style: VeltraTextStyles.headline()),
                                const SizedBox(height: 12),
                                if (worker.employeeId != null &&
                                    worker.employeeId!.isNotEmpty)
                                  _DetailRow(
                                    label: 'Employee ID',
                                    value: worker.employeeId!,
                                  ),
                                if (worker.nfcId != null &&
                                    worker.nfcId!.isNotEmpty)
                                  _DetailRow(
                                    label: 'NFC ID',
                                    value: worker.nfcId!,
                                  ),
                                if (worker.age != null)
                                  _DetailRow(
                                    label: 'Age',
                                    value: '${worker.age} yrs',
                                  ),
                                if (worker.heightCm != null)
                                  _DetailRow(
                                    label: 'Height',
                                    value: BodyMetrics.formatHeightCm(
                                      worker.heightCm,
                                      useImperial:
                                          units.heightUnit == MeasureUnit.imperial,
                                    ),
                                  ),
                                if (worker.weightKg != null)
                                  _DetailRow(
                                    label: 'Weight',
                                    value: BodyMetrics.formatWeightKg(
                                      worker.weightKg,
                                      useImperial:
                                          units.weightUnit == MeasureUnit.imperial,
                                    ),
                                  ),
                                if (worker.bmi != null)
                                  _DetailRow(
                                    label: 'BMI',
                                    value:
                                        '${BodyMetrics.formatBmi(worker.bmi)} · ${BodyMetrics.bmiLabel(worker.bmi) ?? ''}',
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    Text('Trend', style: VeltraTextStyles.headline()),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: VeltraColors.glassBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<TrendMetric>(
                                    value: _chartMetric,
                                    isDense: true,
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
                          scansAsync.when(
                            data: (scans) => TrendChart(
                              scans: scans.take(10).toList().reversed.toList(),
                              metric: _chartMetric,
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                  color: VeltraColors.safetyOrange,
                                ),
                              ),
                            ),
                            error: (_, __) => TrendChart(
                              scans: const [],
                              metric: _chartMetric,
                            ),
                          ),
                          const SizedBox(height: 16),
                          scansAsync.when(
                            data: (scans) => ScanHistoryList(
                              scans: scans,
                              onTap: (scan) =>
                                  showScanDetailSheet(context, scan),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const ScanHistoryList(scans: []),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
      },
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: VeltraTextStyles.caption()),
          ),
          Expanded(
            child: Text(value, style: VeltraTextStyles.body()),
          ),
        ],
      ),
    );
  }
}
