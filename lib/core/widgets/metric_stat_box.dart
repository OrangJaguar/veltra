import 'package:flutter/material.dart';

import '../../core/theme/veltra_colors.dart';
import '../../core/theme/veltra_text_styles.dart';

class MetricStatBox extends StatelessWidget {
  const MetricStatBox({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.icon,
    this.accentColor,
  });

  final String label;
  final String value;
  final String? trend;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? VeltraColors.safetyOrange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeltraColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: VeltraColors.shadowWarm.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: VeltraTextStyles.caption(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trend != null)
                Text(
                  trend!,
                  style: VeltraTextStyles.caption(color),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: VeltraTextStyles.headline(),
          ),
        ],
      ),
    );
  }
}
