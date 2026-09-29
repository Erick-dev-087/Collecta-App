import 'package:flutter/material.dart';

import '../../../data/models/collection.dart';
import '../../../data/models/enums.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/status_pill.dart';
import '../../../widgets/ui.dart';
import '../../../widgets/whatsapp_icon.dart';

class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.onCopy,
    required this.onWhatsApp,
    required this.onStk,
    required this.onViewLedger,
  });

  final Collection collection;
  final VoidCallback onCopy;
  final VoidCallback onWhatsApp;
  final VoidCallback onStk;
  final VoidCallback onViewLedger;

  IconData get _icon => switch (collection.category) {
        'Capital Projects' => Icons.church_outlined,
        'Youth & Camps' => Icons.forest_outlined,
        'Welfare' => Icons.volunteer_activism_outlined,
        _ => Icons.hiking,
      };

  @override
  Widget build(BuildContext context) {
    final c = collection;
    final closed = c.status == EventStatus.closed;
    final accent = closed
        ? AppColors.slateBorderStrong
        : (c.category == 'Youth & Camps'
            ? AppColors.chartPending
            : AppColors.mintNeon);
    final unpaid = ((c.memberTarget ?? 0) - c.contributorCount).clamp(0, 9999);

    return SectionCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIconBadge(icon: _icon, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.headlineSm),
                    const SizedBox(height: 2),
                    Text(
                        '${dateShort(c.eventDate)}  •  Quota ${kes(c.defaultAmount)}',
                        style: AppType.bodySm),
                  ],
                ),
              ),
              StatusPill.event(c.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL COLLECTED', style: AppType.labelSm),
                          const SizedBox(height: 2),
                          Text(kes(c.totalCollected),
                              style: AppType.currencyDisplay
                                  .copyWith(fontSize: 26)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ATTENDING', style: AppType.labelSm),
                        Text('${c.contributorCount} / ${c.memberTarget ?? '—'}',
                            style: AppType.currencyMd.copyWith(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('of ${kes(c.targetAmount)}', style: AppType.bodySm),
                const SizedBox(height: 10),
                ProgressBar(value: c.progress, color: accent == AppColors.chartPending ? AppColors.chartPending : AppColors.emeraldDeep),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('${pct(c.progress)} of goal reached',
                        style: AppType.bodySm),
                    const Spacer(),
                    if (!closed)
                      Text('$unpaid remaining', style: AppType.bodySm),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('SHARABLE PAYMENT LINK', style: AppType.labelSm),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.base),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: Text(c.payLink,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.tabular),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(Icons.copy_rounded, onCopy),
              const SizedBox(width: 6),
              _whatsAppBtn(onWhatsApp),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (!closed)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStk,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mintNeon,
                      foregroundColor: AppColors.slateInk,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.base)),
                    ),
                    icon: const Icon(Icons.podcasts, size: 18),
                    label: Text('Trigger STK${unpaid > 0 ? ' ($unpaid)' : ''}'),
                  ),
                ),
              if (!closed) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewLedger,
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('View Ledger'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.base),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: Icon(icon, size: 18, color: AppColors.slateInk),
        ),
      );

  Widget _whatsAppBtn(VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.base),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.mintSurface,
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: const Center(
              child: WhatsAppIcon(size: 20, color: AppColors.emeraldDeep)),
        ),
      );
}
