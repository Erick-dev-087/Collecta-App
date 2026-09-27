import 'package:flutter/material.dart';

/// Collecta "Institutional FinOps" palette (see design system DESIGN.md).
/// Deep institutional emerald anchors trust; energetic mint signals live
/// STK/reconciliation activity; slate neutrals carry dense financial data.
class AppColors {
  AppColors._();

  // Brand
  static const emeraldDeep = Color(0xFF006837);
  static const emeraldHover = Color(0xFF00522B);
  static const primary = Color(0xFF004D27);
  static const primaryContainer = Color(0xFF006837);
  static const mintNeon = Color(0xFF00E599);
  static const mintSurface = Color(0xFFECFDF5);

  // Neutrals / slate
  static const slateInk = Color(0xFF0F172A);
  static const slateSubtle = Color(0xFF64748B);
  static const slateBorder = Color(0xFFE2E8F0);
  static const slateBorderStrong = Color(0xFFCBD5E1);
  static const slateMuted = Color(0xFF94A3B8);

  // Surfaces
  static const canvas = Color(0xFFF8FAFC);
  static const panel = Color(0xFFFFFFFF);
  static const panelAlt = Color(0xFFF2F3FF);

  // Text
  static const textPrimary = slateInk;
  static const textSecondary = Color(0xFF475569);
  static const textMuted = slateSubtle;
  static const onEmerald = Color(0xFFFFFFFF);

  // Status — matched / reconciled
  static const matchedBg = Color(0xFFECFDF5);
  static const matchedText = Color(0xFF047857);
  // Pending STK
  static const pendingBg = Color(0xFFEFF6FF);
  static const pendingText = Color(0xFF1D4ED8);
  // Discrepancy / failed
  static const discrepancyBg = Color(0xFFFEF2F2);
  static const discrepancyText = Color(0xFFB91C1C);
  static const discrepancyAccent = Color(0xFFEF4444);
  // Settled / archived
  static const settledBg = Color(0xFFF1F5F9);
  static const settledText = Color(0xFF475569);

  // Charts
  static const chartMatched = emeraldDeep;
  static const chartDirect = mintNeon;
  static const chartPending = Color(0xFF3B82F6);

  // Elevation shadows
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => const [
        BoxShadow(
          color: Color(0x0F0F172A),
          blurRadius: 15,
          spreadRadius: -3,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 6,
          spreadRadius: -4,
          offset: Offset(0, 4),
        ),
      ];
}
