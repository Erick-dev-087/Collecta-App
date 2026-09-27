import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../collecta_api.dart';
import '../models/analytics.dart';
import '../models/collection.dart';
import '../models/enums.dart';
import '../models/member.dart';
import '../models/organization.dart';
import '../models/payment.dart';

/// Live backend adapter that talks to the Collecta shelf server via standard
/// HTTP POST requests. Firebase Auth provides the ID token for each request.
///
/// To go live: deploy the backend to Render, set [baseUrl] to your Render
/// domain, and flip `useMock` to false in `api_provider.dart`.
class FirebaseCollectaApi implements CollectaApi {
  FirebaseCollectaApi({this.baseUrl = _placeholderBase});

  /// e.g. https://your-app.onrender.com
  final String baseUrl;
  static const _placeholderBase = 'https://your-app.onrender.com';

  final _changesCtrl = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changesCtrl.stream;

  AppUser? _user;
  @override
  AppUser? get currentUser => _user;

  /// Get the current user's Firebase ID token for auth headers.
  Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Make an authenticated POST request to the backend API.
  Future<Map<String, dynamic>> _call(
      String endpoint, [Map<String, dynamic>? data]) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/api$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data ?? const {}),
    );
    if (res.statusCode != 200) {
      final body = _tryDecode(res.body);
      throw Exception(body['error'] ?? 'Request failed (${res.statusCode})');
    }
    return _tryDecode(res.body);
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> res) =>
      ((res['items'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  @override
  Future<AppUser> signIn(
      {required String identifier, required String secret}) async {
    // Firebase Auth owns credentials.
    final cred = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: identifier, password: secret);
    final profile = await _call('/auth/getProfile');
    _user = AppUser(
      uid: cred.user!.uid,
      orgId: '${profile['orgId'] ?? ''}',
      fullName: '${profile['fullName'] ?? ''}',
      email: '${profile['email'] ?? identifier}',
      role: UserRole.fromString(profile['role'] as String?),
    );
    return _user!;
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String organizationName,
    required String email,
    required String phone,
    required String secret,
  }) async {
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: secret);
    await cred.user?.updateDisplayName(fullName);

    // Provision the org + admin profile in the backend.
    final res = await _call('/auth/bootstrapOrganization', {
      'email': email,
      'fullName': fullName,
      'organizationName': organizationName,
      'phone': phone,
    });

    _user = AppUser(
      uid: cred.user!.uid,
      orgId: '${res['orgId']}',
      fullName: fullName,
      email: email,
      role: UserRole.fromString(res['role'] as String?),
    );
    return _user!;
  }

  @override
  Future<void> signOut() => FirebaseAuth.instance.signOut();

  @override
  Future<Organization> getOrganization() async =>
      Organization.fromMap(await _call('/org/getOrganization'));

  @override
  Future<Organization> updateOrganization(Organization org) async => org;

  @override
  Future<List<Member>> listMembers() async =>
      _items(await _call('/members/listMembers')).map(Member.fromMap).toList();

  @override
  Future<Member> createMember(Map<String, dynamic> data) async {
    final res = await _call('/members/createMember', data);
    return Member.fromMap({...data, ...res});
  }

  @override
  Future<void> deleteMember(String memberId) =>
      _call('/members/deleteMember', {'memberId': memberId});

  @override
  Future<List<Collection>> listCollections() async =>
      _items(await _call('/events/listEvents'))
          .map(Collection.fromMap)
          .toList();

  @override
  Future<Collection> createCollection(Map<String, dynamic> data) async {
    final res = await _call('/events/createEvent', data);
    return Collection.fromMap({...data, ...res});
  }

  @override
  Future<EventAnalytics> eventAnalytics(String eventId) async {
    final m = await _call('/events/eventAnalytics', {'eventId': eventId});
    return EventAnalytics(
      eventId: eventId,
      title: '${m['title'] ?? ''}',
      targetAmount: m['targetAmount'] as num?,
      totalCollected: (m['totalCollected'] as num?) ?? 0,
      completedPayments: (m['completedPayments'] as num?)?.toInt() ?? 0,
      pendingPayments: (m['pendingPayments'] as num?)?.toInt() ?? 0,
      failedPayments: (m['failedPayments'] as num?)?.toInt() ?? 0,
      uniqueContributors: (m['uniqueContributors'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<Payment>> paymentHistory({String? eventId}) async {
    final res = await _call('/payments/paymentHistory',
        eventId != null ? {'eventId': eventId} : null);
    return _items(res).map(Payment.fromMap).toList();
  }

  @override
  Future<StkResult> initiatePayment({
    required String eventId,
    required String phone,
    int? amount,
    String? payerName,
  }) async {
    final data = <String, dynamic>{
      'eventId': eventId,
      'phone': phone,
    };
    if (amount != null) data['amount'] = amount;
    if (payerName != null) data['payerName'] = payerName;
    final res = await _call('/payments/initiatePayment', data);
    return StkResult(
      paymentId: '${res['paymentId'] ?? ''}',
      status: '${res['status'] ?? 'pending'}',
      customerMessage: '${res['customerMessage'] ?? ''}',
    );
  }

  @override
  Future<int> triggerBulkStk(String eventId) async {
    // No dedicated callable; the client fans out per unpaid member.
    return 0;
  }

  @override
  Future<DashboardMetrics> dashboard() async {
    // Composed client-side from listEvents + paymentHistory in a full build.
    throw UnimplementedError('Wire dashboard aggregation against live data.');
  }
}