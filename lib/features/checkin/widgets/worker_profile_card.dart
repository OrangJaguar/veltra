import 'package:flutter/material.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/utils/body_metrics.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/worker.dart';

class WorkerProfileCard extends StatelessWidget {
  const WorkerProfileCard({
    super.key,
    required this.worker,
    this.onEdit,
  });

  final Worker worker;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final bmiLabel = BodyMetrics.bmiLabel(worker.bmi);
    final bmi = worker.bmi == null
        ? 'Not set'
        : '${BodyMetrics.formatBmi(worker.bmi)}${bmiLabel == null ? '' : ' · $bmiLabel'}';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Profile', style: VeltraTextStyles.headline())),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: VeltraColors.safetyOrange,
                  tooltip: 'Edit profile',
                ),
            ],
          ),
          _line('Employee ID', _text(worker.employeeId)),
          _line('Age', worker.age == null ? 'Not set' : '${worker.age}'),
          _line(
            'Height',
            worker.heightCm == null
                ? 'Not set'
                : BodyMetrics.formatHeightCm(worker.heightCm, useImperial: false),
          ),
          _line(
            'Weight',
            worker.weightKg == null
                ? 'Not set'
                : BodyMetrics.formatWeightKg(worker.weightKg, useImperial: false),
          ),
          _line('BMI', bmi),
          _line('Pod', _text(worker.podId)),
        ],
      ),
    );
  }

  String _text(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Not set';
    return trimmed;
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: VeltraTextStyles.body(VeltraColors.textSecondary)),
          ),
          Text(value, style: VeltraTextStyles.body()),
        ],
      ),
    );
  }
}
