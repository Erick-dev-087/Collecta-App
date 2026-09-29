import 'models/analytics.dart';
import 'models/collection.dart';
import 'models/member.dart';
import 'models/organization.dart';
import 'models/payment.dart';

/// Result of kicking off an STK push.
class StkResult {
  const StkResult({
    required this.paymentId,
    required this.status,
    required this.customerMessage,
  });
  final String paymentId;
  final String status;
  final String customerMessage;
}

/// Abstraction over the Collecta backend. Two implementations exist:
///  - [MockCollectaApi]  — in-memory seeded data (default; runs offline).
///  - [FirebaseCollectaApi] — real `httpsCallableFromUrl` adapter.
///
/// Method names and payload shapes mirror the deployed Dart callables so
/// switching implementations is a one-line change (see `api_provider.dart`).
abstract class CollectaApi {
  // Auth ---------------------------------------------------------------------
  Future<AppUser> signIn({required String identifier, required String secret});

  /// Register a brand-new organization + its first administrator, then return
  /// the signed-in user. Mirrors a `registerOrganization` backend callable.
  Future<AppUser> register({
    required String fullName,
    required String organizationName,
    required String email,
    required String phone,
    required String secret,
  });

  Future<void> signOut();
  AppUser? get currentUser;

  // Organization -------------------------------------------------------------
  Future<Organization> getOrganization();
  Future<Organization> updateOrganization(Organization org);

  // Members ------------------------------------------------------------------
  Future<List<Member>> listMembers();
  Future<Member> createMember(Map<String, dynamic> data);
  Future<void> deleteMember(String memberId);

  // Collections / events -----------------------------------------------------
  Future<List<Collection>> listCollections();
  Future<Collection> createCollection(Map<String, dynamic> data);
  Future<EventAnalytics> eventAnalytics(String eventId);

  // Payments -----------------------------------------------------------------
  Future<List<Payment>> paymentHistory({String? eventId});

  /// Initiate one STK push toward [eventId]. In mock mode the returned payment
  /// transitions initiated -> pending -> completed over a few seconds.
  Future<StkResult> initiatePayment({
    required String eventId,
    required String phone,
    int? amount,
    String? payerName,
  });

  /// Record a manual cash payment.
  Future<void> recordCash({
    required String eventId,
    required String phone,
    required int amount,
    String? payerName,
  });

  /// Trigger STK for every member of [eventId] who has not fully paid.
  /// Returns the number of prompts dispatched.
  Future<int> triggerBulkStk(String eventId);

  // Dashboard ----------------------------------------------------------------
  Future<DashboardMetrics> dashboard();

  /// Emits whenever mock payment state changes (so live views refresh). Live
  /// implementation may return an empty stream.
  Stream<void> get changes;
}
