import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_provider.dart';
import '../data/models/analytics.dart';
import '../data/models/collection.dart';
import '../data/models/member.dart';
import '../data/models/organization.dart';
import '../data/models/payment.dart';
import '../utils/ledger.dart';

/// All data providers refresh when the backend emits a change
/// (`backendChangesProvider`) — e.g. the mock STK lifecycle completing.

final organizationProvider = FutureProvider<Organization>((ref) async {
  ref.watch(backendChangesProvider);
  return ref.watch(collectaApiProvider).getOrganization();
});

final membersProvider = FutureProvider<List<Member>>((ref) async {
  ref.watch(backendChangesProvider);
  return ref.watch(collectaApiProvider).listMembers();
});

final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  ref.watch(backendChangesProvider);
  return ref.watch(collectaApiProvider).listCollections();
});

final dashboardProvider = FutureProvider<DashboardMetrics>((ref) async {
  ref.watch(backendChangesProvider);
  return ref.watch(collectaApiProvider).dashboard();
});

/// Payment history, optionally scoped to one collection.
final paymentsProvider =
    FutureProvider.family<List<Payment>, String?>((ref, eventId) async {
  ref.watch(backendChangesProvider);
  return ref.watch(collectaApiProvider).paymentHistory(eventId: eventId);
});

/// Reconciled ledger rows for a collection (members joined with payments).
final ledgerProvider =
    FutureProvider.family<List<LedgerEntry>, String>((ref, eventId) async {
  ref.watch(backendChangesProvider);
  final api = ref.watch(collectaApiProvider);
  final collections = await api.listCollections();
  final collection = collections.firstWhere((c) => c.id == eventId);
  final members = await api.listMembers();
  final payments = await api.paymentHistory(eventId: eventId);
  return buildLedger(collection, members, payments);
});
