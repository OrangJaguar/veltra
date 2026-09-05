import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/veltra_colors.dart';
import '../../core/theme/veltra_text_styles.dart';
import '../../core/widgets/veltra_gradient_background.dart';
import '../../core/widgets/veltra_nav_bar.dart';
import '../auth/providers/auth_providers.dart';

class MainShell extends ConsumerWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  VeltraTab _tabFromIndex(int index) {
    switch (index) {
      case 0:
        return VeltraTab.scan;
      case 1:
        return VeltraTab.crew;
      case 2:
        return VeltraTab.settings;
      default:
        return VeltraTab.scan;
    }
  }

  void _onTabSelected(VeltraTab tab) {
    final index = switch (tab) {
      VeltraTab.scan => 0,
      VeltraTab.crew => 1,
      VeltraTab.settings => 2,
    };
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      extendBody: true,
      body: VeltraGradientBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Text('Veltra', style: VeltraTextStyles.headline()),
                    const Spacer(),
                    if (profile != null && profile.crewName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: VeltraColors.hardHatYellow.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          profile.crewName,
                          style: VeltraTextStyles.caption(
                            VeltraColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
            Expanded(
              child: navigationShell,
            ),
          ],
        ),
      ),
      bottomNavigationBar: VeltraNavBar(
        currentTab: _tabFromIndex(navigationShell.currentIndex),
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
