import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import '../config/context.dart';
import '../config/params.dart';
import '../constants/enums.dart';
import '../utils/csv.dart';
import '../utils/errors.dart';
import '../utils/phone.dart';
import '../utils/validation.dart';
import 'daraja_service.dart';
import 'event_service.dart';
import 'member_service.dart';
import 'org_service.dart';

/// PaymentService is the financial engine: it initiates STK pushes, processes
/// Daraja callbacks, reconciles stuck transactions, and exports history.
class PaymentService {
  PaymentService(
    this.ctx, {
    required this.daraja,
    required this.members,
    required this.events,
    required this.orgs,
  });

  final AppContext ctx;
  final DarajaService daraja;
  final MemberService members;
  final EventService events;
  final OrgService orgs;

  /// Initiate an STK Push for a contribution toward an event.
  ///
  /// Resolves the amount (explicit, else the event default), auto-registers the
  /// payer as a member if new, writes an `initiated` payment record, triggers
  /// the STK push, and stores the returned CheckoutRequestID for reconciliation.
  Future<Map<String, dynamic>> initiate({
    required String orgId,
    required String eventId,
    required String phone,
    int? amount,
    String? payerName,
    String? paymentLinkId,
  }) async {
    final normalizedPhone = normalizePhone(phone);
    final event = await events.get(orgId, eventId);
    if (event['status'] == EventStatus.closed) {
      failedPrecondition('This event is closed for contributions');
    }

    // Determine amount.
    final allowCustom = event['allowCustomAmount'] == true;
    final defaultAmount = event['defaultAmount'] as num?;
    int resolvedAmount;
    if (amount != null) {
      if (!allowCustom && defaultAmount != null && amount != defaultAmount) {
        failedPrecondition('This event requires a fixed amount of $defaultAmount');
      }
      resolvedAmount = requirePositiveAmount(amount, 'amount');
    } else if (defaultAmount != null) {
      resolvedAmount = defaultAmount.toInt();
    } else {
      badRequest('An amount is required for this event');
    }

    // Resolve destination (org-specific or platform default).
    final dest = await orgs.resolveDestination(orgId);
    final shortcode = dest?.shortcode ?? Env.darajaShortcode;
    final passkey = dest?.passkey ?? Env.darajaPasskey;
    final txnType = dest?.transactionType ?? 'CustomerPayBillOnline';
    final accountRef = (dest?.accountNumber?.isNotEmpty == true)
        ? dest!.accountNumber!
        : '${event['title']}';

    // Auto-register payer as a member.
    final memberId =
        await members.findOrCreateByPhone(orgId, normalizedPhone, name: payerName);

    // Create the payment record up-front (status: initiated).
    final paymentId = newId();
    final ts = nowIso();
    await ctx.payments.doc(paymentId).set({
      'orgId': orgId,
      'eventId': eventId,
      'memberId': memberId,
      'paymentLinkId': paymentLinkId,
      'channel': PaymentChannel.stkPush,
      'payerName': payerName,
      'phone': normalizedPhone,
      'amount': resolvedAmount,
      'status': PaymentStatus.initiated,
      'accountReference': accountRef,
      'mpesaReceiptNumber': null,
      'checkoutRequestId': null,
      'merchantRequestId': null,
      'resultCode': null,
      'resultDesc': null,
      'initiatedAt': ts,
      'completedAt': null,
      'updatedAt': ts,
    });

    // Trigger the STK push.
    try {
      final result = await daraja.stkPush(StkPushParams(
        amount: resolvedAmount,
        phone: normalizedPhone,
        shortcode: shortcode,
        passkey: passkey,
        transactionType: txnType,
        accountReference: accountRef,
        description: 'Contribution',
        callbackUrl: '${Env.publicCallbackBaseUrl}/darajaCallback',
      ));
      await ctx.payments.doc(paymentId).update({
        'status': PaymentStatus.pending,
        'checkoutRequestId': result.checkoutRequestId,
        'merchantRequestId': result.merchantRequestId,
        'updatedAt': nowIso(),
      });
      return {
        'paymentId': paymentId,
        'checkoutRequestId': result.checkoutRequestId,
        'customerMessage': result.customerMessage,
        'status': PaymentStatus.pending,
      };
    } catch (e) {
      // Mark the record failed so it is not left dangling as "initiated".
      await ctx.payments.doc(paymentId).update({
        'status': PaymentStatus.failed,
        'resultDesc': 'STK push failed: $e',
        'updatedAt': nowIso(),
      });
      rethrow;
    }
  }

  // APPEND_MARKER

  /// Record a manual cash payment.
  Future<Map<String, dynamic>> recordCash({
    required String orgId,
    required String eventId,
    required String phone,
    required int amount,
    String? payerName,
  }) async {
    final normalizedPhone = normalizePhone(phone);
    final event = await events.get(orgId, eventId);
    if (event['status'] == EventStatus.closed) {
      failedPrecondition('This event is closed for contributions');
    }

    final resolvedAmount = requirePositiveAmount(amount, 'amount');

    // Auto-register payer as a member.
    final memberId =
        await members.findOrCreateByPhone(orgId, normalizedPhone, name: payerName);

    final paymentId = newId();
    final ts = nowIso();
    
    await ctx.payments.doc(paymentId).set({
      'orgId': orgId,
      'eventId': eventId,
      'memberId': memberId,
      'paymentLinkId': null,
      'channel': PaymentChannel.cash,
      'payerName': payerName,
      'phone': normalizedPhone,
      'amount': resolvedAmount,
      'status': PaymentStatus.completed,
      'accountReference': 'Cash',
      'mpesaReceiptNumber': null,
      'checkoutRequestId': null,
      'merchantRequestId': null,
      'resultCode': 0,
      'resultDesc': 'Manual cash entry',
      'initiatedAt': ts,
      'completedAt': ts,
      'updatedAt': ts,
    });

    // Fold into member + event aggregates.
    await members.applyContribution(orgId, memberId, resolvedAmount);
    await events.applyCompletedPayment(orgId, eventId, resolvedAmount);

    return {
      'paymentId': paymentId,
      'status': PaymentStatus.completed,
    };
  }

  /// Process an asynchronous Daraja STK callback. Idempotent: a repeated
  /// callback for an already-finalised payment is stored but does not
  /// double-count aggregates.
  Future<void> handleCallback(
    Map<String, dynamic> rawBody,
    StkCallback cb,
  ) async {
    // Always persist the raw payload for auditing/debugging.
    await ctx.paymentCallbacks.doc(newId()).set({
      'checkoutRequestId': cb.checkoutRequestId,
      'merchantRequestId': cb.merchantRequestId,
      'resultCode': cb.resultCode,
      'processed': false,
      'raw': rawBody,
      'receivedAt': nowIso(),
    });

    if (cb.checkoutRequestId == null) return;
    final snap = await ctx.payments
        .where('checkoutRequestId', '==', cb.checkoutRequestId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return; // unknown/foreign callback
    final doc = snap.docs.first;
    final payment = doc.data() ?? const {};

    // Idempotency: skip if already terminal.
    if (!PaymentStatus.nonTerminal.contains(payment['status'])) return;

    if (cb.isSuccess) {
      await ctx.payments.doc(doc.id).update({
        'status': PaymentStatus.completed,
        'mpesaReceiptNumber': cb.mpesaReceiptNumber,
        'resultCode': cb.resultCode,
        'resultDesc': cb.resultDesc,
        'completedAt': nowIso(),
        'updatedAt': nowIso(),
      });
      // Fold into member + event aggregates.
      final amount = cb.amount ?? (payment['amount'] as num? ?? 0);
      final orgId = '${payment['orgId']}';
      if (payment['memberId'] != null) {
        await members.applyContribution(orgId, '${payment['memberId']}', amount);
      }
      await events.applyCompletedPayment(orgId, '${payment['eventId']}', amount);
      if (payment['paymentLinkId'] != null) {
        await _incrementLinkCollected('${payment['paymentLinkId']}', amount);
      }
    } else {
      await ctx.payments.doc(doc.id).update({
        'status': PaymentStatus.failed,
        'resultCode': cb.resultCode,
        'resultDesc': cb.resultDesc,
        'updatedAt': nowIso(),
      });
    }
  }

  Future<void> _incrementLinkCollected(String linkId, num amount) async {
    final ref = ctx.paymentLinks.doc(linkId);
    await ctx.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final total = (snap.data()?['totalCollected'] as num?) ?? 0;
      tx.update(ref, {'totalCollected': total + amount});
    });
  }

  Future<Map<String, dynamic>> getStatus(String orgId, String paymentId) async {
    final snap = await ctx.payments.doc(paymentId).get();
    if (!snap.exists) notFound('Payment not found');
    final data = snap.data() ?? const {};
    if (data['orgId'] != orgId) forbidden('Payment does not belong to your organization');
    return {'id': snap.id, ...data};
  }

  /// Payment history for an org (optionally filtered by event).
  Future<List<Map<String, dynamic>>> history(
    String orgId, {
    String? eventId,
    int limit = 100,
  }) async {
    final query = eventId != null
        ? ctx.payments.where('eventId', '==', eventId)
        : ctx.payments.where('orgId', '==', orgId);
    final snap = await query.limit(limit).get();
    final list = snap.docs.map((d) => <String, dynamic>{'id': d.id, ...?d.data()}).toList();
    list.sort((a, b) => '${b['initiatedAt']}'.compareTo('${a['initiatedAt']}'));
    return list;
  }

  /// Payments left non-terminal past the stuck threshold — candidates for
  /// reconciliation.
  Future<List<Map<String, dynamic>>> listStuck(String orgId) async {
    final cutoff = isoMinutesAgo(stuckPaymentMinutes);
    final snap = await ctx.payments.where('orgId', '==', orgId).get();
    return snap.docs
        .map((d) => <String, dynamic>{'id': d.id, ...?d.data()})
        .where((p) =>
            PaymentStatus.nonTerminal.contains(p['status']) &&
            '${p['initiatedAt']}'.compareTo(cutoff) < 0)
        .toList();
  }

  /// Reconcile a single stuck payment by querying Daraja for its final status.
  Future<Map<String, dynamic>> reconcile(String orgId, String paymentId) async {
    final snap = await ctx.payments.doc(paymentId).get();
    if (!snap.exists) notFound('Payment not found');
    final data = snap.data() ?? const {};
    if (data['orgId'] != orgId) forbidden('Payment does not belong to your organization');
    if (!PaymentStatus.nonTerminal.contains(data['status'])) {
      return {'id': paymentId, 'status': data['status'], 'reconciled': false};
    }
    final checkoutId = data['checkoutRequestId'] as String?;
    if (checkoutId == null) {
      badRequest('Payment has no CheckoutRequestID to query');
    }

    final dest = await orgs.resolveDestination(orgId);
    final result = await daraja.queryStk(
      checkoutRequestId: checkoutId,
      shortcode: dest?.shortcode ?? Env.darajaShortcode,
      passkey: dest?.passkey ?? Env.darajaPasskey,
    );

    if (result.resultCode == 0) {
      await ctx.payments.doc(paymentId).update({
        'status': PaymentStatus.completed,
        'resultCode': result.resultCode,
        'resultDesc': result.resultDesc,
        'completedAt': nowIso(),
        'updatedAt': nowIso(),
      });
      final amount = (data['amount'] as num?) ?? 0;
      if (data['memberId'] != null) {
        await members.applyContribution(orgId, '${data['memberId']}', amount);
      }
      await events.applyCompletedPayment(orgId, '${data['eventId']}', amount);
      return {'id': paymentId, 'status': PaymentStatus.completed, 'reconciled': true};
    } else {
      await ctx.payments.doc(paymentId).update({
        'status': PaymentStatus.failed,
        'resultCode': result.resultCode,
        'resultDesc': result.resultDesc,
        'updatedAt': nowIso(),
      });
      return {'id': paymentId, 'status': PaymentStatus.failed, 'reconciled': true};
    }
  }

  /// Export an org's payments as CSV text.
  Future<String> exportCsv(String orgId) async {
    final rows = await history(orgId, limit: 100000);
    const columns = [
      'id',
      'eventId',
      'memberId',
      'payerName',
      'phone',
      'amount',
      'status',
      'channel',
      'mpesaReceiptNumber',
      'checkoutRequestId',
      'initiatedAt',
      'completedAt',
    ];
    return toCsv(rows, columns);
  }

}
