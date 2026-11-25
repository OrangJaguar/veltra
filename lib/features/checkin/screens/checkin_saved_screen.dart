import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../models/check_in.dart';
import '../../../providers/worker_providers.dart';
import '../providers/demo_session_provider.dart';
import '../widgets/checkin_saved_view.dart';
import '../widgets/checkin_trend_chart.dart';

class CheckInSavedScreen extends ConsumerWidget {
  const CheckInSavedScreen({super.key, required this.checkInId});

  final String checkInId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CheckIn?>(
      future: ref.read(checkInRepositoryProvider).getCheckIn(checkInId),
      builder: (context, snapshot) {
        final checkIn = snapshot.data;
        return Scaffold(
          body: VeltraGradientBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: checkIn == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: VeltraColors.safetyOrange,
                        ),
                      )
                    : _SavedBody(checkIn: checkIn),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedBody extends ConsumerWidget {
  const _SavedBody({required this.checkIn});

  final CheckIn checkIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(workerByIdProvider(checkIn.workerId)).valueOrNull;
    final history = ref.watch(workerCheckInsProvider(checkIn.workerId)).valueOrNull;
    final name = worker?.name ?? '';
    final rows = history == null || history.isEmpty ? [checkIn] : history;

    return CheckInSavedView(
      checkIn: checkIn,
      workerName: name,
      trend: (metric) => CheckInTrendChart(
        checkIns: rows,
        metric: metric,
        showHeading: false,
      ),
      onDone: () => context.go('/checkin'),
    );
  }
}
