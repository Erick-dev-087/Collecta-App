import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/analytics.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/ui.dart';
import 'widgets/trend_chart.dart';
import 'widgets/rails_donut.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          color: AppColors.emeraldDeep,
          child: async.when(
            loading: () => const _Loading(),
            error: (e, _) =>
                AsyncStateView(message: 'Could not load overview.\n$e', isError: true),
            data: (m) => _Content(metrics: m),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => ListView(
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator(color: AppColors.emeraldDeep)),
        ],
      );
}

class _Content extends StatelessWidget {
  const _Content({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
      children: [
        CollectaHeader(
          title: 'Overview',
          subtitle: "Here's what's happening with your collections.",
        ),
        const SizedBox(height: AppSpacing.md),
        _metrics(m),
        const SizedBox(height: AppSpacing.md),
        _trendCard(m),
        const SizedBox(height: AppSpacing.md),
        _railsCard(m),
        const SizedBox(height: AppSpacing.md),
        _recentCard(m),
        const SizedBox(height: AppSpacing.md),
        _topCollectionsCard(m),
      ],
    );
  }

  Widget _metrics(DashboardMetrics m) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.gutter,
      crossAxisSpacing: AppSpacing.gutter,
      childAspectRatio: 0.98,
      children: [
        MetricCard(
          label: 'Total Collected',
          value: kes(m.totalCollected),
          caption: '${m.settledReceipts} settled receipts this cycle',
          icon: Icons.payments_outlined,
          tag: '+${m.collectedDeltaPct.toStringAsFixed(1)}%',
        ),
        MetricCard(
          label: 'Active Collections',
          value: '${m.activeCollections}',
          caption: 'Live funds • Building, Tithes & Trips',
          icon: Icons.event_available_outlined,
        ),
        MetricCard(
          label: 'Registered Members',
          value: '${m.registeredMembers}',
          caption: '${pct(m.verifiedPhonePct)} verified mobile numbers',
          icon: Icons.groups_outlined,
          tag: '+${m.newMembers} new',
        ),
        MetricCard(
          label: 'Auto-Recon Rate',
          value: '${m.autoReconRate.toStringAsFixed(1)}%',
          caption: 'Zero unmatched ledger drops',
          icon: Icons.verified_outlined,
          valueColor: AppColors.emeraldDeep,
        ),
      ],
    );
  }

  Widget _trendCard(DashboardMetrics m) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Collection Trends', style: AppType.headlineSm),
          const SizedBox(height: 2),
          Text('Automated M-Pesa STK + Direct Paybill receipts',
              style: AppType.bodySm),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: 170, child: TrendChart(points: m.trend)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.emeraldDeep, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Automated batch scheduled — next sweep in 3h 12m',
                      style: AppType.labelMd
                          .copyWith(color: AppColors.emeraldHover)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railsCard(DashboardMetrics m) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Status & Rails', style: AppType.headlineSm),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              RailsDonut(stkPush: m.stkPushPct),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _railLegend('M-Pesa STK Push', m.stkPushPct,
                        AppColors.emeraldDeep),
                    const SizedBox(height: 10),
                    _railLegend('Direct Paybill', m.directPaybillPct,
                        AppColors.mintNeon),
                    const SizedBox(height: 10),
                    _railLegend('Bank EFT Pending', m.bankPendingPct,
                        AppColors.chartPending),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: AppColors.matchedText),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Safaricom Daraja API Gateway: Connected',
                        style: AppType.labelMd)),
                Text('280ms', style: AppType.tabular),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railLegend(String label, double value, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppType.bodyMd)),
        Text(pct(value), style: AppType.labelLg),
      ],
    );
  }

  Widget _recentCard(DashboardMetrics m) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Transactions', style: AppType.headlineSm),
              const Spacer(),
              Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: AppColors.mintNeon, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('Real-Time', style: AppType.labelSm),
              ]),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final t in m.recent) _recentRow(t),
        ],
      ),
    );
  }

  Widget _recentRow(RecentTransaction t) {
    final initials = t.name.trim().isEmpty
        ? '?'
        : t.name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          InitialsAvatar(initials: initials.toUpperCase(), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: AppType.labelLg),
                Text(t.collection,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodySm),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(kes(t.amount), style: AppType.currencyMd.copyWith(fontSize: 15)),
              const SizedBox(height: 3),
              StatusPill.payment(t.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topCollectionsCard(DashboardMetrics m) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Collections', style: AppType.headlineSm),
          const SizedBox(height: 2),
          Text('Progress toward designated milestones', style: AppType.bodySm),
          const SizedBox(height: AppSpacing.md),
          for (final c in m.topCollections) ...[
            Row(
              children: [
                Text(c.rank.toString().padLeft(2, '0'),
                    style: AppType.labelSm.copyWith(color: AppColors.emeraldDeep)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.labelLg)),
                Text('${kesPlain(c.collected)} / ${kesPlain(c.target)}',
                    style: AppType.tabular),
              ],
            ),
            const SizedBox(height: 6),
            ProgressBar(value: c.progress),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${pct(c.progress)} completed', style: AppType.bodySm),
                const Spacer(),
                Text('${c.contributors} contributors', style: AppType.bodySm),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
