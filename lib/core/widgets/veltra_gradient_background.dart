import 'package:flutter/material.dart';

import '../theme/veltra_colors.dart';

class VeltraGradientBackground extends StatelessWidget {
  const VeltraGradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VeltraColors.sunriseCream,
            VeltraColors.warmSand,
          ],
        ),
      ),
      child: child,
    );
  }
}
