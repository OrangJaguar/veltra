import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'veltra_colors.dart';

abstract final class VeltraTextStyles {
  static TextStyle get _base => GoogleFonts.plusJakartaSans(
        color: VeltraColors.textPrimary,
      );

  static TextStyle display([Color? color]) => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color ?? VeltraColors.textPrimary,
      );

  static TextStyle title([Color? color]) => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color ?? VeltraColors.textPrimary,
      );

  static TextStyle headline([Color? color]) => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? VeltraColors.textPrimary,
      );

  static TextStyle body([Color? color]) => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color ?? VeltraColors.textPrimary,
      );

  static TextStyle label([Color? color]) => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? VeltraColors.textSecondary,
      );

  static TextStyle caption([Color? color]) => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? VeltraColors.textMuted,
      );
}
