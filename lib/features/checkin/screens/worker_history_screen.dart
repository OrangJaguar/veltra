import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../models/check_in.dart';
import '../../../models/sync_status.dart';
import '../checkin_labels.dart';
import '../checkin_risk.dart';
import '../providers/demo_session_provider.dart';
import '../widgets/checkin_saved_view.dart';
import '../widgets/checkin_trend_chart.dart';

class WorkerHistoryScreen extends ConsumerWidget {
  const WorkerHistoryScreen({super.key, required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(workerByIdProvider(workerId)).valueOrNull;

    return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: VeltraColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        worker == null ? 'History' : worker.name,
                        style: VeltraTextStyles.title(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: WorkerHistoryBody(workerId: workerId)),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkerHistoryPage extends ConsumerWidget {
  const WorkerHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(selectedWorkerProvider);
    return worker.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: VeltraColors.safetyOrange),
      ),
      error: (_, __) => Center(
        child: Text('Could not load history', style: VeltraTextStyles.body()),
      ),
      data: (selected) {
        if (selected == null) {
          return Center(
            child: Text(
              'Choose a worker in Settings',
              style: VeltraTextStyles.body(VeltraColors.textSecondary),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(selected.name, style: VeltraTextStyles.title()),
            ),
            Expanded(child: WorkerHistoryBody(workerId: selected.id)),
          ],
        );
      },
    );
  }
}

class WorkerHistoryBody extends ConsumerStatefulWidget {
  const WorkerHistoryBody({super.key, required this.workerId});

  final String workerId;

  @override
  ConsumerState<WorkerHistoryBody> createState() => _WorkerHistoryBodyState();
}

class _WorkerHistoryBodyState extends ConsumerState<WorkerHistoryBody> {
  CheckInMetric _metric = CheckInMetric.forehead;

  @override
  Widget build(BuildContext context) {
    final checkIns = ref.watch(workerCheckInsProvider(widget.workerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<CheckInMetric>(
              value: _metric,
              underline: const SizedBox.shrink(),
              style: VeltraTextStyles.body(),
              items: [
                for (final metric in CheckInMetric.values)
                  DropdownMenuItem(value: metric, child: Text(metric.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _metric = value);
              },
            ),
          ),
        ),
        Expanded(
          child: checkIns.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: VeltraColors.safetyOrange),
            ),
            error: (_, __) => Center(
              child: Text('Could not load history', style: VeltraTextStyles.body()),
            ),
            data: (rows) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  CheckInTrendChart(checkIns: rows, metric: _metric),
                  const SizedBox(height: 16),
                  if (rows.isEmpty)
                    Text(
                      'No check-ins yet',
                      style: VeltraTextStyles.body(VeltraColors.textSecondary),
                    )
                  else
                    for (final checkIn in rows) ...[
                      _HistoryRow(checkIn: checkIn),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.checkIn});

  final CheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final result = scoreCheckIn(checkIn);
    final tone = statusTone(result?.status ?? WorkerStatus.none);
    final source = checkInSourceLabel(checkIn.source);
    final detail = result?.status.label == null
        ? source
        : '$source · ${result!.status.label}';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatCheckInTime(checkIn.capturedAt),
            style: VeltraTextStyles.headline(),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: VeltraTextStyles.caption(
              result == null ? VeltraColors.textMuted : tone.color,
            ),
          ),
        ],
      ),
    );
  }
}
