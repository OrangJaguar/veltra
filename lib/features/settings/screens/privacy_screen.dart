import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeltraColors.sunriseCream,
      appBar: AppBar(
        backgroundColor: VeltraColors.sunriseCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Privacy policy', style: VeltraTextStyles.headline()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What Veltra collects', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                Text(
                  'Veltra stores worker names, optional profile details, and '
                  'heat-stress screening readings (skin temperature, sweat rate, '
                  'salinity, and derived risk scores) to help foremen monitor crew '
                  'safety on site.',
                  style: VeltraTextStyles.body(VeltraColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Text('Where data is stored', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                Text(
                  'Data is saved on your device first and synced to Firebase when '
                  'you are online. You can use the app offline; scans queue until '
                  'connectivity returns.',
                  style: VeltraTextStyles.body(VeltraColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Text('Not a medical device', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                Text(
                  'Veltra provides occupational heat-risk screening only. It does '
                  'not diagnose illness or replace medical judgment. Always follow '
                  'your site safety plan and local regulations.',
                  style: VeltraTextStyles.body(VeltraColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Text('Contact', style: VeltraTextStyles.headline()),
                const SizedBox(height: 12),
                Text(
                  'Questions about data use: support@veltra.app',
                  style: VeltraTextStyles.body(VeltraColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
