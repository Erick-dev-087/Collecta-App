import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/formatters.dart';

/// Donut summarising payment rails, with the dominant STK share centered.
class RailsDonut extends StatelessWidget {
  const RailsDonut({super.key, required this.stkPush});
  final double stkPush;

  @override
  Widget build(BuildContext context) {
    final remainder = (1 - stkPush).clamp(0.0, 1.0);
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: stkPush * 100,
                  color: AppColors.emeraldDeep,
                  radius: 16,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: remainder * 100,
                  color: AppColors.mintNeon,
                  radius: 16,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(pct(stkPush),
                  style: AppType.currencyMd.copyWith(fontSize: 20)),
              Text('STK PUSH', style: AppType.labelSm),
            ],
          ),
        ],
      ),
    );
  }
}
