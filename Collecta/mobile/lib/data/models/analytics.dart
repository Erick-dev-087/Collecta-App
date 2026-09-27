import 'enums.dart';
import 'member.dart';

/// Aggregated dashboard overview.
class DashboardMetrics {
  const DashboardMetrics({
    required this.totalCollected,
    required this.collectedDeltaPct,
    required this.settledReceipts,
    required this.activeCollections,
    required this.registeredMembers,
    required this.newMembers,
    required this.verifiedPhonePct,
    required this.autoReconRate,
    required this.trend,
    required this.recent,
    required this.topCollections,
    required this.stkPushPct,
    required this.directPaybillPct,
    required this.bankPendingPct,
  });

  final num totalCollected;
  final double collectedDeltaPct;
  final int settledReceipts;
  final int activeCollections;
  final int registeredMembers;
  final int newMembers;
  final double verifiedPhonePct;
  final double autoReconRate;

  /// Seven daily points (Mon..Sun) of collected value for the trend chart.
  final List<double> trend;
  final List<RecentTransaction> recent;
  final List<TopCollection> topCollections;

  final double stkPushPct;
  final double directPaybillPct;
  final double bankPendingPct;
}

class RecentTransaction {
  const RecentTransaction({
    required this.name,
    required this.collection,
    required this.amount,
    required this.status,
  });

  final String name;
  final String collection;
  final num amount;
  final PaymentStatus status;
}

class TopCollection {
  const TopCollection({
    required this.rank,
    required this.title,
    required this.collected,
    required this.target,
    required this.contributors,
  });

  final int rank;
  final String title;
  final num collected;
  final num target;
  final int contributors;

  double get progress =>
      target <= 0 ? 0 : (collected / target).clamp(0, 1).toDouble();
}

/// Analytics for a single collection.
class EventAnalytics {
  const EventAnalytics({
    required this.eventId,
    required this.title,
    this.targetAmount,
    required this.totalCollected,
    required this.completedPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.uniqueContributors,
  });

  final String eventId;
  final String title;
  final num? targetAmount;
  final num totalCollected;
  final int completedPayments;
  final int pendingPayments;
  final int failedPayments;
  final int uniqueContributors;

  double? get progress {
    final t = targetAmount;
    if (t == null || t <= 0) return null;
    return (totalCollected / t).clamp(0, 1).toDouble();
  }
}

/// One reconciled contributor row for the ledger view (member + how much of
/// the expected amount they have settled).
class LedgerEntry {
  const LedgerEntry({
    required this.member,
    required this.paid,
    required this.expected,
    required this.status,
    this.receipt,
    this.lastPaidAt,
  });

  final Member member;
  final num paid;
  final num expected;
  final PaidStatus status;
  final String? receipt;
  final DateTime? lastPaidAt;
}
