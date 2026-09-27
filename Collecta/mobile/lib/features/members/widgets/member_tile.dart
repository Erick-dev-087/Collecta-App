import 'package:flutter/material.dart';

import '../../../data/models/member.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/ui.dart';

/// One contributor row in the directory.
class MemberTile extends StatelessWidget {
  const MemberTile({super.key, required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final upToDate = m.contributionCount > 0;
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          InitialsAvatar(initials: m.initials, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(m.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.labelLg),
                    ),
                    const SizedBox(width: 6),
                    Text('#${m.id}', style: AppType.labelSm),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(m.phone, style: AppType.tabular),
                    const SizedBox(width: 8),
                    _carrierChip(m),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (m.group != null) ...[
                      const Icon(Icons.groups_2_outlined,
                          size: 13, color: AppColors.slateMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(m.group!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySm),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(kes(m.totalContributed),
                  style: AppType.currencyMd.copyWith(fontSize: 15)),
              const SizedBox(height: 5),
              _duesChip(upToDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _carrierChip(Member m) {
    final isStk = m.carrier == 'STK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isStk ? AppColors.mintSurface : AppColors.pendingBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isStk ? Icons.verified : Icons.sim_card,
              size: 11,
              color: isStk ? AppColors.matchedText : AppColors.pendingText),
          const SizedBox(width: 3),
          Text(isStk ? 'STK' : 'Airtel',
              style: AppType.labelSm.copyWith(
                  color: isStk ? AppColors.matchedText : AppColors.pendingText,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }

  Widget _duesChip(bool upToDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: upToDate ? AppColors.matchedBg : AppColors.discrepancyBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(upToDate ? 'Up to date' : 'Pending',
          style: AppType.labelSm.copyWith(
              color: upToDate ? AppColors.matchedText : AppColors.discrepancyText,
              letterSpacing: 0.2)),
    );
  }
}
