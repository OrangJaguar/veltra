import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/sync_status.dart';
import '../../../models/worker.dart';

class WorkerListTile extends StatelessWidget {
  const WorkerListTile({
    super.key,
    required this.worker,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  final Worker worker;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  Color get _statusColor {
    switch (worker.lastStatus) {
      case WorkerStatus.green:
        return VeltraColors.statusGreen;
      case WorkerStatus.amber:
        return VeltraColors.statusAmber;
      case WorkerStatus.red:
        return VeltraColors.statusRed;
      case WorkerStatus.none:
      case null:
        return VeltraColors.textMuted;
    }
  }

  String get _subtitle {
    final parts = <String>[];
    if (worker.employeeId != null && worker.employeeId!.isNotEmpty) {
      parts.add('ID ${worker.employeeId}');
    }
    if (worker.nfcId != null && worker.nfcId!.isNotEmpty) {
      parts.add('NFC ${worker.nfcId}');
    }
    if (worker.lastStatus?.label != null) {
      parts.add(worker.lastStatus!.label!);
    }
    if (worker.lastScanAt != null) {
      parts.add(_relativeTime(worker.lastScanAt!));
    }
    if (parts.isEmpty && worker.bmi != null) {
      parts.add('BMI ${worker.bmi!.toStringAsFixed(1)}');
    }
    return parts.take(3).join(' · ');
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  WorkerAvatar(
                    name: worker.name,
                    photoPath: worker.photoPath,
                    radius: 24,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name, style: VeltraTextStyles.headline()),
                    if (_subtitle.isNotEmpty)
                      Text(
                        _subtitle,
                        style: VeltraTextStyles.caption(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!worker.synced)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: VeltraColors.coneAmber,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                color: VeltraColors.textMuted,
                onPressed: () => _showMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: VeltraColors.sunriseCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: VeltraColors.safetyOrange),
              title: Text('Edit worker', style: VeltraTextStyles.body()),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: VeltraColors.statusRed),
              title: Text('Remove worker', style: VeltraTextStyles.body()),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      onEdit();
    } else if (action == 'delete') {
      onDelete();
    }
  }
}
