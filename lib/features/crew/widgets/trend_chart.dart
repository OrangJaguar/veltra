import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/scan_record.dart';
import '../../../providers/scan_providers.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.scans,
    required this.metric,
    this.highlightLatest = false,
  });

  final List<ScanRecord> scans;
  final TrendMetric metric;
  final bool highlightLatest;

  @override
  Widget build(BuildContext context) {
    final chronological = scans.reversed.toList();
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
          Text('Trend', style: VeltraTextStyles.headline()),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: VeltraTextStyles.caption(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: points.isEmpty
                ? _EmptyChart(message: 'No data yet')
                : hasLine
                    ? LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: VeltraColors.textMuted.withOpacity(0.15),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toStringAsFixed(1),
                                  style: VeltraTextStyles.caption(),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: points.length <= 6,
                                reservedSize: 22,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= chronological.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final time = chronological[index].timestamp;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      DateFormat('M/d').format(time),
                                      style: VeltraTextStyles.caption(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: points,
                              isCurved: true,
                              color: VeltraColors.safetyOrange,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) {
                                  final isLast = index == points.length - 1;
                                  return FlDotCirclePainter(
                                    radius: isLast && highlightLatest ? 6 : 4,
                                    color: isLast && highlightLatest
                                        ? VeltraColors.statusRed
                                        : VeltraColors.safetyOrange,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: VeltraColors.safetyOrange.withOpacity(0.12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _SinglePointChart(
                        value: points.first.y,
                        unit: metric.unit,
                      ),
          ),
          if (!hasLine && points.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Log more scans to see a trend line',
              style: VeltraTextStyles.caption(),
            ),
          ],
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
            color: VeltraColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(message, style: VeltraTextStyles.caption()),
        ],
      ),
    );
  }
}

class _SinglePointChart extends StatelessWidget {
  const _SinglePointChart({required this.value, required this.unit});

  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toStringAsFixed(1),
            style: VeltraTextStyles.display(VeltraColors.safetyOrange),
          ),
          if (unit.isNotEmpty)
            Text(unit, style: VeltraTextStyles.caption()),
          const SizedBox(height: 6),
          Text(
            'First reading — keep scanning',
            style: VeltraTextStyles.caption(),
          ),
        ],
      ),
    );
  }
}
