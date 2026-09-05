import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'veltra_colors.dart';
import 'veltra_text_styles.dart';

abstract final class VeltraTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: VeltraColors.safetyOrange,
      onPrimary: VeltraColors.textOnOrange,
      secondary: VeltraColors.hardHatYellow,
      surface: VeltraColors.sunriseCream,
      onSurface: VeltraColors.textPrimary,
      error: VeltraColors.statusRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: VeltraColors.sunriseCream,
      textTheme: TextTheme(
        displayLarge: VeltraTextStyles.display(),
        titleLarge: VeltraTextStyles.title(),
        titleMedium: VeltraTextStyles.headline(),
        bodyLarge: VeltraTextStyles.body(),
        bodyMedium: VeltraTextStyles.body(VeltraColors.textSecondary),
        labelLarge: VeltraTextStyles.label(),
        bodySmall: VeltraTextStyles.caption(),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: VeltraColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: VeltraTextStyles.title(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: VeltraColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: VeltraColors.glassBorder.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: VeltraColors.safetyOrange, width: 2),
        ),
        hintStyle: VeltraTextStyles.body(VeltraColors.textMuted),
        labelStyle: VeltraTextStyles.label(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
