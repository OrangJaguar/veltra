import 'package:flutter/material.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../models/check_in.dart';
import '../checkin_labels.dart';

class MeasurementPanel extends StatefulWidget {
  const MeasurementPanel({
    super.key,
    required this.checkIn,
    this.initiallyExpanded = false,
  });

  final CheckIn checkIn;
  final bool initiallyExpanded;

  @override
  State<MeasurementPanel> createState() => _MeasurementPanelState();
}

class _MeasurementPanelState extends State<MeasurementPanel> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final checkIn = widget.checkIn;
    final rows = [
      _Row('Forehead temperature', _value(checkIn.foreheadTempC, '°C')),
      _Row('Strip volume', _value(checkIn.stripVolumeUl, 'µL')),
      _Row(
        'Sweat conductivity',
        _value(checkIn.conductivityUsCm, 'µS/cm', decimals: 0),
      ),
      _Row(
        'Sweat rate',
        _value(checkIn.sweatRateUlMin, 'µL/min'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.initiallyExpanded)
          Text('Measurements', style: VeltraTextStyles.headline())
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _open = !_open),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(52, 52),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                _open ? 'Hide measurements' : 'Measurements',
                style: VeltraTextStyles.headline(),
              ),
            ),
          ),
        if (_open) ...[
          const SizedBox(height: 8),
          ...rows,
        ],
      ],
    );
  }

  String _value(double? value, String unit, {int decimals = 1}) {
    final shown = formatMeasurement(value, decimals: decimals);
    if (value == null) return shown;
    return '$shown $unit';
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final missing = value == 'Unavailable';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: VeltraTextStyles.body(VeltraColors.textSecondary)),
          ),
          Text(
            value,
            style: VeltraTextStyles.body(
              missing ? VeltraColors.textMuted : VeltraColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
