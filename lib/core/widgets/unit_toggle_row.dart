import 'package:flutter/material.dart';

import '../theme/veltra_colors.dart';
import '../theme/veltra_text_styles.dart';
import '../utils/unit_preferences.dart';

class UnitToggleRow extends StatelessWidget {
  const UnitToggleRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final MeasureUnit selected;
  final ValueChanged<MeasureUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: VeltraTextStyles.label()),
        const Spacer(),
        _Chip(
          text: 'Metric',
          selected: selected == MeasureUnit.metric,
          onTap: () => onChanged(MeasureUnit.metric),
        ),
        const SizedBox(width: 8),
        _Chip(
          text: 'Imperial',
          selected: selected == MeasureUnit.imperial,
          onTap: () => onChanged(MeasureUnit.imperial),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? VeltraColors.safetyOrange
              : VeltraColors.warmSand.withOpacity(0.8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? VeltraColors.safetyOrange
                : VeltraColors.glassBorder.withOpacity(0.5),
          ),
        ),
        child: Text(
          text,
          style: VeltraTextStyles.caption(
            selected ? VeltraColors.textOnOrange : VeltraColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
