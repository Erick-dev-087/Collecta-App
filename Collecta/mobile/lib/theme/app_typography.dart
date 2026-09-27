import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type system: Plus Jakarta Sans for headlines + key financial figures,
/// Inter for body and dense tabular ledgers. Monetary/ledger styles enable
/// tabular figures + slashed zero so thousands of rows stay column-aligned.
class AppType {
  AppType._();

  static const _tnum = [
    FontFeature.tabularFigures(),
    FontFeature('cv05'), // slashed zero (Inter)
  ];

  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height / size,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
    List<FontFeature>? features,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height / size,
        letterSpacing: letterSpacing,
        color: color,
        fontFeatures: features,
      );

  // Headlines (Plus Jakarta Sans)
  static TextStyle get headlineXl =>
      _jakarta(size: 32, weight: FontWeight.w800, height: 40, letterSpacing: -0.8);
  static TextStyle get headlineLg =>
      _jakarta(size: 26, weight: FontWeight.w700, height: 34, letterSpacing: -0.5);
  static TextStyle get headlineMd =>
      _jakarta(size: 22, weight: FontWeight.w700, height: 30, letterSpacing: -0.4);
  static TextStyle get headlineSm =>
      _jakarta(size: 18, weight: FontWeight.w600, height: 26, letterSpacing: -0.27);

  // Currency / key metrics (Plus Jakarta Sans, tabular)
  static TextStyle get currencyDisplay => _jakarta(
        size: 30,
        weight: FontWeight.w800,
        height: 38,
        letterSpacing: -0.9,
      ).copyWith(fontFeatures: _tnum);
  static TextStyle get currencyMd => _jakarta(
        size: 20,
        weight: FontWeight.w700,
        height: 26,
        letterSpacing: -0.4,
      ).copyWith(fontFeatures: _tnum);

  // Body (Inter)
  static TextStyle get bodyLg =>
      _inter(size: 16, weight: FontWeight.w400, height: 24, letterSpacing: -0.16);
  static TextStyle get bodyMd =>
      _inter(size: 14, weight: FontWeight.w400, height: 22, letterSpacing: -0.07);
  static TextStyle get bodySm =>
      _inter(size: 12, weight: FontWeight.w400, height: 18, color: AppColors.textSecondary);

  // Labels (Inter, semibold)
  static TextStyle get labelLg =>
      _inter(size: 14, weight: FontWeight.w600, height: 20, letterSpacing: 0.14);
  static TextStyle get labelMd =>
      _inter(size: 12, weight: FontWeight.w600, height: 16, letterSpacing: 0.24);
  static TextStyle get labelSm => _inter(
        size: 11,
        weight: FontWeight.w700,
        height: 14,
        letterSpacing: 0.44,
        color: AppColors.textMuted,
      );

  // Tabular mono figures for ledgers.
  static TextStyle get tabular => _inter(
        size: 13,
        weight: FontWeight.w500,
        height: 20,
        features: _tnum,
      );
}
