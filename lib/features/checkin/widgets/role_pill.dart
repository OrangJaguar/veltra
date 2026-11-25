import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../models/demo_config.dart';

/// Skinny glass role switch. The selected segment slides.
class RolePill extends StatelessWidget {
  const RolePill({
    super.key,
    required this.role,
    required this.onChanged,
  });

  final String role;
  final ValueChanged<String> onChanged;

  static const _roles = [
    DemoRoles.worker,
    DemoRoles.supervisor,
    DemoRoles.demoAdmin,
  ];

  static const _labels = ['Worker', 'Supervisor', 'Admin'];

  int get _index {
    final index = _roles.indexOf(role);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: VeltraColors.glassBorder),
          ),
          child: SizedBox(
            height: 34,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segment = constraints.maxWidth / _roles.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: segment * _index,
                      top: 2,
                      bottom: 2,
                      width: segment,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x142C2416),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _roles.length; i++)
                          Expanded(
                            child: _Segment(
                              label: _labels[i],
                              selected: i == _index,
                              onTap: () => _select(_roles[i]),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _select(String next) {
    if (next == role) return;
    HapticFeedback.selectionClick();
    onChanged(next);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VeltraTextStyles.caption(
              selected ? VeltraColors.textPrimary : VeltraColors.textMuted,
            ).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
