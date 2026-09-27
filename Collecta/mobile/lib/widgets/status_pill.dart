import 'package:flutter/material.dart';

import '../data/models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Compact rounded-full status chip with an SVG dot, following the design
/// system's absolute status semantics.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.showDot = true,
    this.border,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool showDot;
  final Color? border;

  factory StatusPill.payment(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return const StatusPill(
            label: 'Verified', bg: AppColors.matchedBg, fg: AppColors.matchedText);
      case PaymentStatus.pending:
      case PaymentStatus.initiated:
        return const StatusPill(
            label: 'Pending PIN', bg: AppColors.pendingBg, fg: AppColors.pendingText);
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return const StatusPill(
            label: 'Failed', bg: AppColors.discrepancyBg, fg: AppColors.discrepancyText);
    }
  }

  factory StatusPill.event(EventStatus status) {
    switch (status) {
      case EventStatus.active:
        return const StatusPill(
            label: 'Active', bg: AppColors.matchedBg, fg: AppColors.matchedText);
      case EventStatus.draft:
        return const StatusPill(
            label: 'Draft', bg: AppColors.pendingBg, fg: AppColors.pendingText);
      case EventStatus.closed:
        return const StatusPill(
            label: 'Settled',
            bg: AppColors.settledBg,
            fg: AppColors.settledText,
            border: AppColors.slateBorder);
      case EventStatus.cancelled:
        return const StatusPill(
            label: 'Cancelled',
            bg: AppColors.discrepancyBg,
            fg: AppColors.discrepancyText);
      case EventStatus.expired:
        return const StatusPill(
            label: 'Expired',
            bg: AppColors.pendingBg,
            fg: AppColors.pendingText,
            border: AppColors.slateBorder);
    }
  }

  factory StatusPill.paid(PaidStatus status) {
    switch (status) {
      case PaidStatus.full:
        return const StatusPill(
            label: 'Paid Full', bg: AppColors.matchedBg, fg: AppColors.matchedText);
      case PaidStatus.partial:
        return const StatusPill(
            label: 'Partial', bg: AppColors.pendingBg, fg: AppColors.pendingText);
      case PaidStatus.pending:
        return const StatusPill(
            label: 'Pending', bg: AppColors.discrepancyBg, fg: AppColors.discrepancyText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: AppType.labelSm.copyWith(color: fg, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}
