import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/check_in.dart';
import 'checkin_metric.dart';

export 'checkin_metric.dart';

class CheckInTrendChart extends StatelessWidget {
  const CheckInTrendChart({
    super.key,
    required this.checkIns,
    required this.metric,
    this.showHeading = true,
  });

  final List<CheckIn> checkIns;
  final CheckInMetric metric;
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final chronological = checkIns.reversed.toList();
    final points = <FlSpot>[];
    for (var i = 0; i < chronological.length; i++) {
      final value = metric.valueFrom(chronological[i]);
      if (value != null) points.add(FlSpot(i.toDouble(), value));
    }
    final hasLine = points.length >= 2;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeading) ...[
            Text('Trend', style: VeltraTextStyles.headline()),
            const SizedBox(height: 4),
            Text(metric.label, style: VeltraTextStyles.caption()),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 180,
            child: hasLine
                ? _line(points, chronological)
                : const _EmptyChart(message: 'Not enough data'),
          ),
        ],
      ),
    );
  }

  Widget _line(List<FlSpot> points, List<CheckIn> chronological) {
    final ys = points.map((spot) => spot.y);
    final low = ys.reduce((a, b) => a < b ? a : b);
    final high = ys.reduce((a, b) => a > b ? a : b);
    final span = high - low;
    final pad = span == 0 ? 1.0 : span * 0.2;
    final interval = span == 0 ? 1.0 : span / 4;

    return LineChart(
      LineChartData(
        minY: low - pad,
        maxY: high + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: VeltraColors.textMuted.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: VeltraTextStyles.caption(),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: chronological.length <= 6,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chronological.length) {
                  return const SizedBox.shrink();
                }
                if ((value - index).abs() > 0.01) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('M/d').format(chronological[index].capturedAt.toLocal()),
                    style: VeltraTextStyles.caption(),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: VeltraColors.safetyOrange,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: VeltraColors.safetyOrange.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 36,
            color: VeltraColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(message, style: VeltraTextStyles.caption()),
        ],
      ),
    );
  }
}
