import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/scan_record.dart';
import '../../../models/sync_status.dart';

class ScanHistoryList extends StatelessWidget {
  const ScanHistoryList({
    super.key,
    required this.scans,
    this.onTap,
  });

  final List<ScanRecord> scans;
  final void Function(ScanRecord scan)? onTap;

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 40,
              color: VeltraColors.safetyOrange.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text('No scans yet', style: VeltraTextStyles.headline()),
            const SizedBox(height: 6),
            Text(
              'Scan from the Scan tab',
              style: VeltraTextStyles.body(VeltraColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Scan history', style: VeltraTextStyles.headline()),
        ),
        ...scans.map((scan) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScanHistoryTile(
                scan: scan,
                onTap: onTap == null ? null : () => onTap!(scan),
              ),
            )),
      ],
    );
  }
}

class _ScanHistoryTile extends StatelessWidget {
  const _ScanHistoryTile({required this.scan, this.onTap});

  final ScanRecord scan;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (scan.status) {
      case WorkerStatus.green:
        return VeltraColors.statusGreen;
      case WorkerStatus.amber:
        return VeltraColors.statusAmber;
      case WorkerStatus.red:
        return VeltraColors.statusRed;
      case WorkerStatus.none:
        return VeltraColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d · h:mm a').format(scan.timestamp);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: VeltraTextStyles.body()),
                  const SizedBox(height: 4),
                  Text(
                    '${scan.skinTemp.toStringAsFixed(1)}°C · '
                    '${scan.salinity.toStringAsFixed(0)} salinity · '
                    '${scan.status.label ?? '—'}',
                    style: VeltraTextStyles.caption(),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: VeltraColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

void showScanDetailSheet(BuildContext context, ScanRecord scan) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: VeltraColors.sunriseCream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan details', style: VeltraTextStyles.title()),
            const SizedBox(height: 12),
            _detailRow('Status', scan.status.label ?? '—'),
            _detailRow('Skin temp', '${scan.skinTemp.toStringAsFixed(1)} °C'),
            _detailRow('Sweat rate', '${scan.sweatRate.toStringAsFixed(2)} L/hr'),
            _detailRow('Salinity', '${scan.salinity.toStringAsFixed(0)} mmol/L'),
            if (scan.zScore != null)
              _detailRow('Z-score', scan.zScore!.toStringAsFixed(2)),
            if (scan.wbgt != null)
              _detailRow('WBGT', '${scan.wbgt!.toStringAsFixed(1)} °C'),
            if (scan.recommendation != null) ...[
              const SizedBox(height: 8),
              Text(scan.recommendation!, style: VeltraTextStyles.body()),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: VeltraTextStyles.caption())),
        Expanded(child: Text(value, style: VeltraTextStyles.body())),
      ],
    ),
  );
}
