import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../providers/demo_session_provider.dart';
import '../widgets/manual_checkin_sheet.dart';

class WorkerHomeScreen extends ConsumerWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(selectedWorkerProvider).valueOrNull;
    final window = ref.watch(openCheckInWindowProvider).valueOrNull;
    final weatherAsync = ref.watch(optionalWeatherProvider);
    final followUp = ref.watch(selectedFollowUpProvider).valueOrNull;
    final canCheckIn = worker != null && window != null && window.isOpen;

    final weatherLabel = weatherAsync.when(
      data: (weather) {
        if (weather == null || weather.wbgt == null) return 'Weather unavailable';
        final kind = weather.source == 'cached' ? 'Cached' : 'Estimated';
        final air = weather.airTempC == null
            ? ''
            : '${weather.airTempC!.toStringAsFixed(0)}°C · ';
        return '$kind $air WBGT ${weather.wbgt!.toStringAsFixed(0)}';
      },
      loading: () => 'Weather …',
      error: (_, __) => 'Weather unavailable',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: _WeatherChip(label: weatherLabel),
              ),
              const SizedBox(width: 10),
              Text(
                worker?.name ?? 'Worker',
                style: VeltraTextStyles.headline(),
              ),
            ],
          ),
          if (followUp != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recheck requested',
                style: VeltraTextStyles.body(VeltraColors.safetyOrange),
              ),
            ),
          ],
          if (!canCheckIn) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No open window.',
                style: VeltraTextStyles.body(VeltraColors.textSecondary),
              ),
            ),
          ],
          const Spacer(),
          _CheckInCircle(
            enabled: canCheckIn,
            onPressed: canCheckIn
                ? () {
                    context.push(
                      '/checkin/session?workerId=${worker.id}&windowId=${window.id}',
                    );
                  }
                : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: canCheckIn
                ? () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ManualCheckInSheet(
                        workerId: worker.id,
                        windowId: window.id,
                      ),
                    );
                  }
                : null,
            child: Text(
              'Manual entry',
              style: VeltraTextStyles.body(
                canCheckIn ? VeltraColors.textMuted : VeltraColors.textMuted.withValues(alpha: 0.4),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VeltraColors.skyWorkBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded, size: 16, color: VeltraColors.skyWorkBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VeltraTextStyles.caption(VeltraColors.skyWorkBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInCircle extends StatelessWidget {
  const _CheckInCircle({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final circle = Material(
      color: VeltraColors.safetyOrange,
      shape: const CircleBorder(),
      elevation: enabled ? 8 : 0,
      shadowColor: VeltraColors.safetyOrange.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 220,
          height: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sensors_rounded,
                size: 52,
                color: VeltraColors.textOnOrange,
              ),
              const SizedBox(height: 10),
              Text(
                'Check in',
                style: VeltraTextStyles.headline(VeltraColors.textOnOrange),
              ),
            ],
          ),
        ),
      ),
    );

    final shown = Opacity(opacity: enabled ? 1 : 0.45, child: circle);
    if (!enabled) return shown;
    return shown
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          duration: 1800.ms,
          curve: Curves.easeInOut,
        );
  }
}
