import 'package:firebase_admin_sdk/auth.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

/// Shared server context: a Firestore handle, an Auth handle, and typed
/// collection accessors. Constructed once inside `runFunctions` from
/// `firebase.adminApp` and threaded into every service.
///
/// Design note: all timestamps are stored as ISO-8601 UTC **strings** (see
/// [nowIso]). Strings are JSON-safe for callable responses and sort in the
/// same order as time, so the composite indexes on `initiatedAt`,
/// `lastContributionAt`, etc. behave correctly for range/order queries.
class AppContext {
  AppContext({required this.db, required this.auth});

  final Firestore db;
  final Auth auth;

  CollectionReference get users => db.collection('users');
  CollectionReference get organizations => db.collection('organizations');
  CollectionReference get payments => db.collection('payments');
  CollectionReference get paymentLinks => db.collection('paymentLinks');
  CollectionReference get paymentCallbacks => db.collection('paymentCallbacks');

  CollectionReference paymentDestinations(String orgId) =>
      organizations.doc(orgId).collection('paymentDestinations');
  CollectionReference members(String orgId) =>
      organizations.doc(orgId).collection('members');
  CollectionReference events(String orgId) =>
      organizations.doc(orgId).collection('events');
}

/// Current time as an ISO-8601 UTC string (sortable, JSON-safe).
String nowIso() => DateTime.now().toUtc().toIso8601String();

/// ISO-8601 UTC string for a point [minutes] in the past.
String isoMinutesAgo(int minutes) =>
    DateTime.now().toUtc().subtract(Duration(minutes: minutes)).toIso8601String();

const _idAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// Generate a 20-character collision-resistant document ID (Firestore-style),
/// avoiding reliance on the package's auto-id behaviour.
String newId() {
  var seed = DateTime.now().microsecondsSinceEpoch ^ 0x5DEECE66D;
  final buf = StringBuffer();
  for (var i = 0; i < 20; i++) {
    seed = (seed * 6364136223846793005 + 1442695040888963407) &
        0x7fffffffffffffff;
    buf.write(_idAlphabet[(seed >> 17) % _idAlphabet.length]);
  }
  return buf.toString();
}
