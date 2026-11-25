import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/metric_stat_box.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/check_in.dart';
import '../../../models/sync_status.dart';
import '../checkin_labels.dart';
import '../checkin_risk.dart';
import 'checkin_metric.dart';

class CheckInSavedView extends StatefulWidget {
  const CheckInSavedView({
    super.key,
    required this.checkIn,
    required this.workerName,
    required this.trend,
    required this.onDone,
  });

  final CheckIn checkIn;
  final String workerName;
  final Widget Function(CheckInMetric metric) trend;
  final VoidCallback onDone;

  @override
  State<CheckInSavedView> createState() => _CheckInSavedViewState();
}

class _CheckInSavedViewState extends State<CheckInSavedView> {
  CheckInMetric _metric = CheckInMetric.forehead;

  @override
  Widget build(BuildContext context) {
    final checkIn = widget.checkIn;
    final result = scoreCheckIn(checkIn);
    final status = result?.status ?? WorkerStatus.none;
    final tone = statusTone(status);
    final name = widget.workerName.trim().isEmpty ? 'Worker' : widget.workerName.trim();

    final tiles = <Widget>[
      MetricStatBox(
        label: 'Forehead',
        value: _reading(checkIn.foreheadTempC, '°C', checkIn.foreheadTempAvailable),
        icon: Icons.thermostat_rounded,
        accentColor: tone.color,
      ),
      MetricStatBox(
        label: 'Strip volume',
        value: _reading(checkIn.stripVolumeUl, 'µL', checkIn.stripVolumeAvailable),
        icon: Icons.water_drop_outlined,
        accentColor: tone.color,
      ),
      MetricStatBox(
        label: 'Conductivity',
        value: _reading(
          checkIn.conductivityUsCm,
          'µS/cm',
          checkIn.conductivityAvailable,
          decimals: 0,
        ),
        icon: Icons.bolt_rounded,
        accentColor: tone.color,
      ),
      MetricStatBox(
        label: 'Sweat rate',
        value: _reading(checkIn.sweatRateUlMin, 'µL/min', checkIn.sweatRateAvailable),
        icon: Icons.speed_rounded,
        accentColor: tone.color,
      ),
    ];
    final wbgt = _wbgt(checkIn);
    if (wbgt != null) {
      tiles.add(
        MetricStatBox(
          label: 'WBGT',
          value: '${wbgt.toStringAsFixed(1)} °C',
          icon: Icons.wb_sunny_outlined,
          accentColor: VeltraColors.skyWorkBlue,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              _Header(
                name: name,
                statusLabel: result?.status.label ?? 'Saved',
                action: result?.recommendation,
                caption:
                    '${formatCheckInTime(checkIn.capturedAt)} · ${checkInSourceLabel(checkIn.source)}',
                tone: tone,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: tiles,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Trend', style: VeltraTextStyles.headline()),
                  const Spacer(),
                  DropdownButton<CheckInMetric>(
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
                ],
              ),
              widget.trend(_metric),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
              .moveY(begin: 24, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
        ),
        const SizedBox(height: 12),
        VeltraPrimaryButton(
          label: 'Done',
          onPressed: widget.onDone,
        ),
      ],
    );
  }

  String _reading(double? value, String unit, bool available, {int decimals = 1}) {
    if (!available || value == null) return 'Unavailable';
    return '${formatMeasurement(value, decimals: decimals)} $unit';
  }

  double? _wbgt(CheckIn checkIn) {
    final weather = checkIn.weather;
    if (weather == null || weather.wbgt == null) return null;
    if (weather.source == WeatherContextSources.unavailable) return null;
    return weather.wbgt;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.statusLabel,
    required this.action,
    required this.caption,
    required this.tone,
  });

  final String name;
  final String statusLabel;
  final String? action;
  final String caption;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tone.color, width: 3),
            ),
            child: WorkerAvatar(name: name, radius: 36),
          ),
          const SizedBox(height: 10),
          Text(
            statusLabel,
            style: VeltraTextStyles.display(tone.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(name, style: VeltraTextStyles.title(), textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 6),
            Text(
              action!,
              style: VeltraTextStyles.body(VeltraColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            caption,
            style: VeltraTextStyles.caption(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StatusTone {
  const StatusTone(this.color, this.background);

  final Color color;
  final Color background;
}

StatusTone statusTone(WorkerStatus status) {
  switch (status) {
    case WorkerStatus.green:
      return const StatusTone(VeltraColors.statusGreen, VeltraColors.statusGreenBg);
    case WorkerStatus.amber:
      return const StatusTone(VeltraColors.statusAmber, VeltraColors.statusAmberBg);
    case WorkerStatus.red:
      return const StatusTone(VeltraColors.statusRed, VeltraColors.statusRedBg);
    case WorkerStatus.none:
      return const StatusTone(VeltraColors.textMuted, VeltraColors.warmSand);
  }
}
