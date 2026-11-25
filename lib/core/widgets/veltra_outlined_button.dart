import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/veltra_colors.dart';
import '../theme/veltra_text_styles.dart';

class VeltraOutlinedButton extends StatefulWidget {
  const VeltraOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  State<VeltraOutlinedButton> createState() => _VeltraOutlinedButtonState();
}

class _VeltraOutlinedButtonState extends State<VeltraOutlinedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.selectionClick();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 52,
          width: widget.expanded ? double.infinity : null,
          padding: widget.expanded
              ? null
              : const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? VeltraColors.safetyOrange
                  : VeltraColors.safetyOrange.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: VeltraTextStyles.body(
              enabled
                  ? VeltraColors.safetyOrange
                  : VeltraColors.safetyOrange.withValues(alpha: 0.4),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
