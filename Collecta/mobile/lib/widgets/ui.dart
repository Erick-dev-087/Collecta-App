import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// White surface card (Level 1) with the design system's border + ambient shadow.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  /// Optional top accent stripe (e.g. active collection).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.slateBorder),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accent != null) Container(height: 4, color: accent),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: card,
    );
  }
}

/// Rounded soft-tinted badge holding an icon (metric card / list leading).
class SoftIconBadge extends StatelessWidget {
  const SoftIconBadge({
    super.key,
    required this.icon,
    this.bg = AppColors.mintSurface,
    this.fg = AppColors.emeraldDeep,
    this.size = 40,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

/// Thin rounded progress track.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.emeraldDeep,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.slateBorder,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Circular initials avatar.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.bg = AppColors.mintSurface,
    this.fg = AppColors.emeraldDeep,
  });

  final String initials;
  final double size;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(initials,
          style: AppType.labelMd.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
