import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/veltra_colors.dart';
import '../theme/veltra_text_styles.dart';

class VeltraPrimaryButton extends StatefulWidget {
  const VeltraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  @override
  State<VeltraPrimaryButton> createState() => _VeltraPrimaryButtonState();
}

class _VeltraPrimaryButtonState extends State<VeltraPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled
                ? VeltraColors.safetyOrange
                : VeltraColors.safetyOrange.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: VeltraColors.safetyOrange.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: VeltraColors.textOnOrange,
                  ),
                )
              : Text(
                  widget.label,
                  style: VeltraTextStyles.body(VeltraColors.textOnOrange).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
