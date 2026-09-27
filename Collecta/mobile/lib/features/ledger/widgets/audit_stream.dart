import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/payment.dart';
import '../../../state/data_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/status_pill.dart';
import '../../../widgets/ui.dart';

/// Direct Safaricom Daraja settlement log tied to member profiles.
class AuditStream extends ConsumerWidget {
  const AuditStream({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentsProvider(eventId));
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('M-Pesa Verified Audit Stream', style: AppType.headlineSm),
          const SizedBox(height: 2),
          Text('Direct Safaricom Daraja settlement logs.', style: AppType.bodySm),
          const SizedBox(height: AppSpacing.md),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.emeraldDeep)),
            ),
            error: (e, _) => Text('$e', style: AppType.bodySm),
            data: (payments) {
              if (payments.isEmpty) {
                return Text('No settlement records yet.', style: AppType.bodySm);
              }
              return Column(
                children: [
                  for (var i = 0; i < payments.length; i++) ...[
                    _row(payments[i]),
                    if (i != payments.length - 1)
                      const Divider(height: 1, color: AppColors.slateBorder),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(Payment p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.payerName ?? 'Member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelLg),
                const SizedBox(height: 2),
                Text(p.mpesaReceiptNumber ?? 'REQ-${p.id.substring(p.id.length - 5)}',
                    style: AppType.tabular.copyWith(
                        color: p.mpesaReceiptNumber != null
                            ? AppColors.slateInk
                            : AppColors.pendingText)),
                Text(timestampAudit(p.completedAt ?? p.initiatedAt),
                    style: AppType.bodySm),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(kes(p.amount),
                    style: AppType.currencyMd.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(p.maskedPhone,
                    style: AppType.bodySm, textAlign: TextAlign.right),
                const SizedBox(height: 4),
                StatusPill.payment(p.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
