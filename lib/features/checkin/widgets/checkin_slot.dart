import 'package:flutter/material.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';

/// Plain titled page. Later plans replace these with the real screens.
class CheckInSlot extends StatelessWidget {
  const CheckInSlot({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: VeltraTextStyles.title(VeltraColors.textMuted),
      ),
    );
  }
}
