import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/veltra_colors.dart';
import '../theme/veltra_text_styles.dart';

enum VeltraTab { scan, crew, settings }

class VeltraNavBar extends StatelessWidget {
  const VeltraNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final VeltraTab currentTab;
  final ValueChanged<VeltraTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 8 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: VeltraColors.glassBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: VeltraColors.navShadow,
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.sensors_rounded,
                    label: 'Scan',
                    selected: currentTab == VeltraTab.scan,
                    onTap: () => _select(VeltraTab.scan),
                  ),
                  _NavItem(
                    icon: Icons.groups_rounded,
                    label: 'Crew',
                    selected: currentTab == VeltraTab.crew,
                    onTap: () => _select(VeltraTab.crew),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    selected: currentTab == VeltraTab.settings,
                    onTap: () => _select(VeltraTab.settings),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(VeltraTab tab) {
    if (tab != currentTab) {
      HapticFeedback.selectionClick();
    }
    onTabSelected(tab);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: selected
                    ? VeltraColors.safetyOrange
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected
                    ? VeltraColors.textOnOrange
                    : VeltraColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VeltraTextStyles.caption(
                selected ? VeltraColors.safetyOrange : VeltraColors.textMuted,
              ).copyWith(fontSize: 10, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}
