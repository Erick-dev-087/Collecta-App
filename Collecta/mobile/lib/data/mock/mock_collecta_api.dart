import 'dart:async';

import '../collecta_api.dart';
import '../models/analytics.dart';
import '../models/collection.dart';
import '../models/enums.dart';
import '../models/member.dart';
import '../models/organization.dart';
import '../models/payment.dart';

/// In-memory Collecta backend seeded with data drawn from the product designs
/// (PCEA Kimuchu church treasury). Simulates the async M-Pesa STK lifecycle so
/// the whole app is exercisable offline.
class MockCollectaApi implements CollectaApi {
  MockCollectaApi() {
    _seed();
  }

  final _changesCtrl = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changesCtrl.stream;

  AppUser? _user;
  @override
  AppUser? get currentUser => _user;

  late Organization _org;
  final List<Member> _members = [];
  final List<Collection> _collections = [];
  final List<Payment> _payments = [];
  int _receiptSeq = 7819;

  static const _orgId = 'org_pcea_kimuchu';

  void _emit() => _changesCtrl.add(null);

  void _seed() {
    _org = const Organization(
      id: _orgId,
      name: 'PCEA Kimuchu Church',
      slug: 'pcea-kimuchu',
      description: 'Institutional church treasury on Collecta.',
      classification: 'Faith-Based / Church',
      currency: 'KES',
      treasuryEmail: 'treasury@pceakimuchu.org',
      verificationPhone: '+254712345678',
      destinations: [
        PaymentDestination(
          id: 'dest_1',
          type: PaymentDestinationType.paybill,
          shortcode: '522522',
          accountNumber: 'PCEA-KIMUCHU',
          name: 'Kimuchu Parish Account',
          hasPasskey: true,
          isActive: true,
          isDefault: true,
        ),
      ],
    );

    // name, phone, group, carrier, verified
    const seed = <List<Object>>[
      ['Stephen Deron', '0712000345', "Elders Session", 'STK', true],
      ['Grace Muthoni', '0720555812', 'Choir', 'STK', true],
      ['David K. Mwangi', '0701777991', "Men's Fellowship", 'STK', true],
      ['Mary Wambui', '0722123456', 'Choir', 'STK', true],
      ['John Kamau', '0795890725', 'Youth Guild', 'STK', true],
      ['Alice Wanjiku', '0711987654', 'Women', 'STK', true],
      ['Patrick Kariuki', '0720444888', "Men's Fellowship", 'STK', true],
      ['Faith Chebet', '0728991200', 'Brigade', 'STK', true],
      ['Evans Mutua', '0733555222', 'Youth Guild', 'Airtel', false],
      ['Nancy Kerubo', '0712334455', 'Choir', 'STK', true],
      ['Samuel Kimani', '0729111222', "Men's Fellowship", 'STK', true],
      ['Beatrice Njeri', '0710222333', 'Women', 'STK', true],
      ['George Kamau', '0795890111', 'Youth Guild', 'STK', true],
      ['Sarah Odhiambo', '0733555999', 'Choir', 'Airtel', false],
      ['Joyce Wangari', '0728991777', 'Brigade', 'STK', true],
      ['Peter Ochieng', '0712000890', 'Youth Guild', 'STK', true],
      ['Samuel Kariuki', '0795000725', "Men's Fellowship", 'STK', true],
      ['Linda Chepkirui', '0722000410', 'Women', 'STK', true],
    ];
    for (var i = 0; i < seed.length; i++) {
      final s = seed[i];
      _members.add(Member(
        id: 'PCEA-${(i + 1).toString().padLeft(3, '0')}',
        fullName: s[0] as String,
        phone: s[1] as String,
        group: s[2] as String,
        carrier: s[3] as String,
        stkVerified: s[4] as bool,
      ));
    }

    _seedCollections();
    _seedNgongPayments();

    _user = const AppUser(
      uid: 'uid_stephen',
      orgId: _orgId,
      fullName: 'Stephen Deron',
      email: 'treasury@pceakimuchu.org',
      role: UserRole.admin,
      roleTitle: 'Treasurer',
    );
  }

  void _seedCollections() {
    _collections.addAll([
      Collection(
        id: 'evt_ngong',
        title: 'Ngong Hills Trip',
        category: 'Trips & Events',
        description: 'Fellowship hiking excursion to the Ngong Hills.',
        eventDate: DateTime(2026, 8, 26),
        defaultAmount: 3000,
        targetAmount: 150000,
        memberTarget: 50,
        status: EventStatus.active,
        shortCode: 'ngong-hills-2026',
        createdAt: DateTime(2026, 7, 20),
      ),
      Collection(
        id: 'evt_building',
        title: 'Church Building & Renovation Fund',
        category: 'Capital Projects',
        description: 'Phase 1 sanctuary roofing and renovation.',
        eventDate: DateTime(2026, 12, 31),
        defaultAmount: 10000,
        targetAmount: 1000000,
        memberTarget: 100,
        status: EventStatus.active,
        shortCode: 'pcea-building',
        totalCollected: 480000,
        contributorCount: 48,
        paymentCount: 48,
        createdAt: DateTime(2026, 1, 15),
      ),
      Collection(
        id: 'evt_youth',
        title: 'Youth Camp Retreat 2026',
        category: 'Youth & Camps',
        description: 'Annual youth mentorship and camp retreat.',
        eventDate: DateTime(2026, 11, 12),
        defaultAmount: 2000,
        targetAmount: 60000,
        memberTarget: 30,
        status: EventStatus.active,
        shortCode: 'pcea-youth',
        totalCollected: 45000,
        contributorCount: 22,
        paymentCount: 22,
        createdAt: DateTime(2026, 6, 5),
      ),
      Collection(
        id: 'evt_welfare',
        title: 'Benevolent Welfare Q1',
        category: 'Welfare',
        description: 'Quarterly benevolent welfare, audited and closed.',
        eventDate: DateTime(2026, 3, 31),
        defaultAmount: 1000,
        targetAmount: 120000,
        memberTarget: 120,
        status: EventStatus.closed,
        shortCode: 'benevolent-welfare-q1',
        totalCollected: 120000,
        contributorCount: 120,
        paymentCount: 120,
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);
  }

  String _nextReceipt() {
    const tail = ['KL9', 'MN2', 'PQ4', 'RS1', 'TU8', 'VW0', 'XY5', 'ZA3',
      'BC7', 'DE9', 'FG2', 'HI6', 'JK1', 'LM4', 'NP7'];
    final r = 'SBL$_receiptSeq${tail[(_receiptSeq - 7819) % tail.length]}';
    _receiptSeq++;
    return r;
  }

  void _seedNgongPayments() {
    final base = DateTime(2026, 8, 26, 8, 30);
    for (var i = 0; i < _members.length; i++) {
      final member = _members[i];
      final PaymentStatus status;
      final num amount;
      if (i < 12) {
        status = PaymentStatus.completed;
        amount = 3000;
      } else if (i < 15) {
        status = PaymentStatus.completed;
        amount = 1500; // partial
      } else {
        status = PaymentStatus.pending;
        amount = 3000;
      }
      final ts = base.add(Duration(minutes: i * 7));
      _payments.add(Payment(
        id: 'pay_ngong_$i',
        orgId: _orgId,
        eventId: 'evt_ngong',
        memberId: member.id,
        payerName: member.fullName,
        phone: member.phone,
        amount: amount,
        status: status,
        mpesaReceiptNumber:
            status == PaymentStatus.completed ? _nextReceipt() : null,
        checkoutRequestId: 'ws_CO_${ts.millisecondsSinceEpoch}',
        initiatedAt: ts,
        completedAt: status == PaymentStatus.completed ? ts : null,
      ));
      if (status == PaymentStatus.completed) {
        _members[i] = _bumpMember(member, amount, ts);
      }
    }
    // A few contributions on other funds for a richer history/dashboard.
    _payments.addAll([
      Payment(
        id: 'pay_build_1', orgId: _orgId, eventId: 'evt_building',
        memberId: 'PCEA-004', payerName: 'Mary Wambui', phone: '0722123456',
        amount: 5000, status: PaymentStatus.completed,
        mpesaReceiptNumber: _nextReceipt(),
        initiatedAt: DateTime(2026, 9, 22, 9, 12),
        completedAt: DateTime(2026, 9, 22, 9, 12),
      ),
      Payment(
        id: 'pay_youth_1', orgId: _orgId, eventId: 'evt_youth',
        memberId: 'PCEA-016', payerName: 'Peter Ochieng', phone: '0712000890',
        amount: 2000, status: PaymentStatus.pending,
        initiatedAt: DateTime(2026, 9, 23, 10, 29),
      ),
    ]);
    _recompute('evt_ngong');
  }

  Member _bumpMember(Member m, num amount, DateTime at) => Member(
        id: m.id, fullName: m.fullName, phone: m.phone, email: m.email,
        gender: m.gender, group: m.group, carrier: m.carrier,
        stkVerified: m.stkVerified, autoCreated: m.autoCreated,
        totalContributed: m.totalContributed + amount,
        contributionCount: m.contributionCount + 1,
        lastContributionAt: at,
      );

  void _recompute(String eventId) {
    final idx = _collections.indexWhere((c) => c.id == eventId);
    if (idx < 0) return;
    final done = _payments.where(
        (p) => p.eventId == eventId && p.status == PaymentStatus.completed);
    final total = done.fold<num>(0, (s, p) => s + p.amount);
    final contributors = done.map((p) => p.memberId).whereType<String>().toSet();
    _collections[idx] = _collections[idx].copyWith(
      totalCollected: total,
      paymentCount: done.length,
      contributorCount: contributors.length,
    );
  }

  Future<T> _delay<T>(T value, [int ms = 350]) =>
      Future.delayed(Duration(milliseconds: ms), () => value);

  @override
  Future<AppUser> signIn(
      {required String identifier, required String secret}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
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
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // Re-brand the seeded org around the new registrant so the rest of the app
    // (Settings, dashboard, receipts) reflects who just signed up.
    _org = _org.copyWith(
      name: organizationName,
      treasuryEmail: email,
      verificationPhone: phone,
    );
    _user = AppUser(
      uid: 'uid_${DateTime.now().millisecondsSinceEpoch}',
      orgId: _orgId,
      fullName: fullName,
      email: email,
      role: UserRole.admin,
      roleTitle: 'Treasurer',
    );
    _emit();
    return _user!;
  }

  @override
  Future<void> signOut() async => _emit();

  @override
  Future<Organization> getOrganization() => _delay(_org);

  @override
  Future<Organization> updateOrganization(Organization org) async {
    _org = org;
    _emit();
    return _delay(_org, 200);
  }

  @override
  Future<List<Member>> listMembers() => _delay(List.unmodifiable(_members));

  @override
  Future<Member> createMember(Map<String, dynamic> data) async {
    final member = Member(
      id: 'PCEA-${(_members.length + 1).toString().padLeft(3, '0')}',
      fullName: '${data['fullName']}',
      phone: '${data['phone']}',
      email: data['email'] as String?,
      gender: data['gender'] as String?,
      group: data['group'] as String?,
    );
    _members.add(member);
    _emit();
    return _delay(member, 200);
  }

  @override
  Future<void> deleteMember(String memberId) async {
    _members.removeWhere((m) => m.id == memberId);
    _emit();
  }

  @override
  Future<List<Collection>> listCollections() =>
      _delay(List.unmodifiable(_collections));

  @override
  Future<Collection> createCollection(Map<String, dynamic> data) async {
    final title = '${data['title']}';
    final c = Collection(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: '${data['category'] ?? 'Trips & Events'}',
      description: data['description'] as String?,
      defaultAmount: data['defaultAmount'] as num?,
      targetAmount: data['targetAmount'] as num?,
      memberTarget: (data['memberTarget'] as num?)?.toInt(),
      allowCustomAmount: data['allowCustomAmount'] as bool? ?? true,
      status: EventStatus.active,
      shortCode:
          title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      createdAt: DateTime.now(),
      paymentDestinationType: data['paymentDestinationType'] as String?,
      paymentShortcode: data['paymentShortcode'] as String?,
      paymentAccountNumber: data['paymentAccountNumber'] as String?,
    );
    _collections.insert(0, c);
    _emit();
    return _delay(c, 200);
  }

  @override
  Future<EventAnalytics> eventAnalytics(String eventId) async {
    final c = _collections.firstWhere((e) => e.id == eventId);
    final ps = _payments.where((p) => p.eventId == eventId);
    return _delay(EventAnalytics(
      eventId: eventId,
      title: c.title,
      targetAmount: c.targetAmount,
      totalCollected: c.totalCollected,
      completedPayments:
          ps.where((p) => p.status == PaymentStatus.completed).length,
      pendingPayments: ps
          .where((p) => !p.status.isTerminal)
          .length,
      failedPayments: ps
          .where((p) =>
              p.status == PaymentStatus.failed ||
              p.status == PaymentStatus.cancelled)
          .length,
      uniqueContributors: ps
          .where((p) => p.status == PaymentStatus.completed)
          .map((p) => p.memberId)
          .whereType<String>()
          .toSet()
          .length,
    ));
  }

  @override
  Future<List<Payment>> paymentHistory({String? eventId}) {
    final list = _payments
        .where((p) => eventId == null || p.eventId == eventId)
        .toList()
      ..sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return _delay(List.unmodifiable(list));
  }

  String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  Member? _findByPhone(String phone) {
    final d = _digits(phone);
    for (final m in _members) {
      final md = _digits(m.phone);
      if (md == d || md.endsWith(d.length >= 9 ? d.substring(d.length - 9) : d)) {
        return m;
      }
    }
    return null;
  }

  @override
  Future<StkResult> initiatePayment({
    required String eventId,
    required String phone,
    int? amount,
    String? payerName,
  }) async {
    final c = _collections.firstWhere((e) => e.id == eventId);
    final amt = amount ?? c.defaultAmount?.toInt() ?? 0;

    var member = _findByPhone(phone);
    if (member == null) {
      member = Member(
        id: 'PCEA-${(_members.length + 1).toString().padLeft(3, '0')}',
        fullName: (payerName != null && payerName.trim().isNotEmpty)
            ? payerName.trim()
            : phone,
        phone: phone,
        autoCreated: true,
      );
      _members.add(member);
    }

    final id = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    _payments.insert(
      0,
      Payment(
        id: id,
        orgId: _orgId,
        eventId: eventId,
        memberId: member.id,
        payerName: member.fullName,
        phone: phone,
        amount: amt,
        status: PaymentStatus.initiated,
        checkoutRequestId: 'ws_CO_$id',
        initiatedAt: DateTime.now(),
      ),
    );
    _emit();
    _runStkLifecycle(id, member.id, eventId, amt);
    return StkResult(
      paymentId: id,
      status: PaymentStatus.pending.wire,
      customerMessage:
          'Success. Request accepted for processing. Enter your M-Pesa PIN.',
    );
  }

  @override
  Future<void> recordCash({
    required String eventId,
    required String phone,
    required int amount,
    String? payerName,
  }) async {
    var member = _findByPhone(phone);
    if (member == null) {
      member = Member(
        id: 'PCEA-${(_members.length + 1).toString().padLeft(3, '0')}',
        fullName: (payerName != null && payerName.trim().isNotEmpty)
            ? payerName.trim()
            : phone,
        phone: phone,
        autoCreated: true,
      );
      _members.add(member);
    }

    final id = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final at = DateTime.now();
    _payments.insert(
      0,
      Payment(
        id: id,
        orgId: _orgId,
        eventId: eventId,
        memberId: member.id,
        payerName: member.fullName,
        phone: phone,
        amount: amount,
        status: PaymentStatus.completed,
        checkoutRequestId: 'cash_$id',
        initiatedAt: at,
        completedAt: at,
      ),
    );
    final mi = _members.indexWhere((m) => m.id == member!.id);
    if (mi >= 0) _members[mi] = _bumpMember(_members[mi], amount, at);
    _recompute(eventId);
    _emit();
  }

  void _patchPayment(String id, Payment Function(Payment) update) {
    final i = _payments.indexWhere((p) => p.id == id);
    if (i >= 0) {
      _payments[i] = update(_payments[i]);
      _emit();
    }
  }

  void _runStkLifecycle(String id, String memberId, String eventId, num amt) {
    Future.delayed(const Duration(milliseconds: 1200), () {
      _patchPayment(id, (p) => p.copyWith(status: PaymentStatus.pending));
    });
    Future.delayed(const Duration(milliseconds: 3200), () {
      final at = DateTime.now();
      _patchPayment(
        id,
        (p) => p.copyWith(
          status: PaymentStatus.completed,
          mpesaReceiptNumber: _nextReceipt(),
          completedAt: at,
        ),
      );
      final mi = _members.indexWhere((m) => m.id == memberId);
      if (mi >= 0) _members[mi] = _bumpMember(_members[mi], amt, at);
      _recompute(eventId);
      _emit();
    });
  }

  @override
  Future<int> triggerBulkStk(String eventId) async {
    final c = _collections.firstWhere((e) => e.id == eventId);
    final expected = (c.defaultAmount ?? 0).toDouble();
    var dispatched = 0;
    for (final m in List<Member>.from(_members)) {
      if (!m.stkVerified) continue;
      final paid = _payments
          .where((p) =>
              p.eventId == eventId &&
              p.memberId == m.id &&
              p.status == PaymentStatus.completed)
          .fold<num>(0, (s, p) => s + p.amount);
      if (paid < expected) {
        await initiatePayment(
            eventId: eventId, phone: m.phone, payerName: m.fullName);
        dispatched++;
        if (dispatched >= 8) break; // keep the demo snappy
      }
    }
    return dispatched;
  }

  @override
  Future<DashboardMetrics> dashboard() async {
    final completed =
        _payments.where((p) => p.status == PaymentStatus.completed);
    final total = completed.fold<num>(0, (s, p) => s + p.amount) + 570000;
    final active =
        _collections.where((c) => c.status == EventStatus.active).length;
    final recent = _payments.take(4).map((p) {
      final c = _collections.firstWhere((e) => e.id == p.eventId,
          orElse: () => _collections.first);
      return RecentTransaction(
        name: p.payerName ?? 'Member',
        collection: c.title,
        amount: p.amount,
        status: p.status,
      );
    }).toList();
    final top = (List<Collection>.from(_collections)
          ..sort((a, b) => b.totalCollected.compareTo(a.totalCollected)))
        .take(3)
        .toList()
        .asMap()
        .entries
        .map((e) => TopCollection(
              rank: e.key + 1,
              title: e.value.title,
              collected: e.value.totalCollected,
              target: e.value.targetAmount ?? 0,
              contributors: e.value.contributorCount,
            ))
        .toList();
    return _delay(DashboardMetrics(
      totalCollected: total,
      collectedDeltaPct: 14.2,
      settledReceipts: completed.length,
      activeCollections: active,
      registeredMembers: _members.length,
      newMembers: 8,
      verifiedPhonePct: 0.89,
      autoReconRate: 99.4,
      trend: const [18, 24, 30, 34, 48.2, 42, 52],
      recent: recent,
      topCollections: top,
      stkPushPct: 0.92,
      directPaybillPct: 0.06,
      bankPendingPct: 0.02,
    ));
  }
}
