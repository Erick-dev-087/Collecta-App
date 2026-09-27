import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'collecta_logo.dart';

/// Standard top region for each tab: a compact brand + org row, then a title
/// and supporting line. Replaces the desktop top bar for mobile.
class CollectaHeader extends StatelessWidget {
  const CollectaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.orgName = 'PCEA Kimuchu',
    this.showBrandRow = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String orgName;
  final bool showBrandRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBrandRow) ...[
          Row(
            children: [
              const CollectaLogo(size: 30),
              const SizedBox(width: 8),
              Text('Collecta',
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              _liveChip(),
              const SizedBox(width: 8),
              const Icon(Icons.notifications_none_rounded,
                  color: AppColors.slateSubtle),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  size: 14, color: AppColors.slateMuted),
              const SizedBox(width: 4),
              Text('$orgName  •  Audited Treasury Workspace',
                  style: AppType.labelSm),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.headlineLg),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: AppType.bodyMd
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ],
    );
  }

  Widget _liveChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.mintSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.emeraldDeep, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('M-Pesa STK Live',
                style: AppType.labelSm.copyWith(color: AppColors.emeraldDeep)),
          ],
        ),
      );
}

/// Simple centered async loader / error used inside tab bodies.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({super.key, required this.message, this.isError = false});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isError ? Icons.error_outline : Icons.hourglass_empty,
                color: isError ? AppColors.discrepancyText : AppColors.slateMuted),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppType.bodyMd.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
