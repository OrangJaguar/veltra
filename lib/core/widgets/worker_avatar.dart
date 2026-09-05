import 'package:flutter/material.dart';

import '../theme/veltra_colors.dart';
import '../theme/veltra_text_styles.dart';
import '../../services/photo_service.dart';

class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.radius = 28,
    this.onTap,
  });

  final String name;
  final String? photoPath;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final file = PhotoService().photoFile(photoPath);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: VeltraColors.hardHatYellow.withOpacity(0.55),
      backgroundImage: file != null ? FileImage(file) : null,
      child: file == null
          ? Text(
              initial,
              style: VeltraTextStyles.headline(VeltraColors.textPrimary),
            )
          : null,
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: VeltraColors.safetyOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: VeltraColors.textOnOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
