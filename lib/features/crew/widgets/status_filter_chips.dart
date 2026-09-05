import 'package:flutter/material.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../models/sync_status.dart';

class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WorkerStatus? selected;
  final ValueChanged<WorkerStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          _FilterChip(
            label: 'Green',
            selected: selected == WorkerStatus.green,
            color: VeltraColors.statusGreen,
            onTap: () => onSelected(WorkerStatus.green),
          ),
          _FilterChip(
            label: 'Amber',
            selected: selected == WorkerStatus.amber,
            color: VeltraColors.statusAmber,
            onTap: () => onSelected(WorkerStatus.amber),
          ),
          _FilterChip(
            label: 'Red',
            selected: selected == WorkerStatus.red,
            color: VeltraColors.statusRed,
            onTap: () => onSelected(WorkerStatus.red),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? VeltraColors.safetyOrange;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? accent.withOpacity(0.18) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? accent : VeltraColors.glassBorder,
              ),
            ),
            child: Text(
              label,
              style: VeltraTextStyles.label(
                selected ? accent : VeltraColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
