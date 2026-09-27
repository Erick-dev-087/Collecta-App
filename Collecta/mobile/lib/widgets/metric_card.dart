import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'ui.dart';

/// Compact overview metric tile: soft icon + optional trailing tag, a big
/// figure, and a caption. Used across Dashboard / Collections / Members.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.tag,
    this.tagColor = AppColors.matchedText,
    this.tagBg = AppColors.matchedBg,
    this.valueColor = AppColors.slateInk,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final String? tag;
  final Color tagColor;
  final Color tagBg;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                SoftIconBadge(icon: icon!, size: 34)
              else
                const SizedBox.shrink(),
              const Spacer(),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(tag!,
                      style: AppType.labelSm
                          .copyWith(color: tagColor, letterSpacing: 0.2)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label.toUpperCase(), style: AppType.labelSm),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.currencyMd.copyWith(color: valueColor)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodySm),
          ],
        ],
      ),
    );
  }
}
