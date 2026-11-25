import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../checkin_nav.dart';

/// Heavier glass dock. Taller and squarer than the role pill.
class CheckInTabBar extends StatelessWidget {
  const CheckInTabBar({
    super.key,
    required this.tabs,
    required this.current,
    required this.onSelected,
  });

  final List<String> tabs;
  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: VeltraColors.glassBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: VeltraColors.navShadow,
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  for (final tab in tabs)
                    Expanded(
                      child: _TabItem(
                        tab: tab,
                        selected: tab == current,
                        onTap: () => _select(tab),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(String tab) {
    if (tab != current) HapticFeedback.selectionClick();
    onSelected(tab);
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final String tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: CheckInTabs.label(tab),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? VeltraColors.safetyOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _icon(tab),
                size: 18,
                color: selected ? VeltraColors.textOnOrange : VeltraColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              CheckInTabs.label(tab),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VeltraTextStyles.caption(
                selected ? VeltraColors.safetyOrange : VeltraColors.textMuted,
              ).copyWith(fontSize: 11, height: 1, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String tab) {
    switch (tab) {
      case CheckInTabs.scan:
        return Icons.sensors_rounded;
      case CheckInTabs.history:
        return Icons.show_chart_rounded;
      case CheckInTabs.settings:
        return Icons.settings_rounded;
      case CheckInTabs.dashboard:
        return Icons.grid_view_rounded;
      case CheckInTabs.workers:
        return Icons.groups_rounded;
      case CheckInTabs.bench:
        return Icons.tune_rounded;
      case CheckInTabs.crew:
        return Icons.badge_rounded;
      case CheckInTabs.tools:
        return Icons.build_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}
