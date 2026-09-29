import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import '../config/context.dart';
import '../config/params.dart';
import '../utils/errors.dart';
import '../utils/validation.dart';

/// PaymentLinkService: shareable short links that open a hosted checkout page
/// for a specific event/amount. The link's `shortCode` is the document ID.
class PaymentLinkService {
  PaymentLinkService(this.ctx);
  final AppContext ctx;

  Future<Map<String, dynamic>> create(
    String orgId,
    String createdBy,
    Map<String, dynamic> data,
  ) async {
    final eventId = requireString(data['eventId'], 'eventId');
    // Validate the event exists and belongs to the org.
    final event = await ctx.events(orgId).doc(eventId).get();
    if (!event.exists) notFound('Event not found');

    final title = optionalString(data['title'], 'title') ?? '${event.data()?['title']}';
    final amount =
        data['amount'] == null ? null : requirePositiveAmount(data['amount'], 'amount');
    final allowCustom = asBool(data['allowCustomAmount'], amount == null);

    // Generate a unique short code.
    String code = randomCode();
    for (var i = 0; i < 5; i++) {
      final clash = await ctx.paymentLinks.doc(code).get();
      if (!clash.exists) break;
      code = randomCode();
    }

    await ctx.paymentLinks.doc(code).set({
      'orgId': orgId,
      'eventId': eventId,
      'shortCode': code,
      'title': title,
      'amount': amount,
      'allowCustomAmount': allowCustom,
      'active': true,
      'clickCount': 0,
      'totalCollected': 0,
      'createdBy': createdBy,
      'createdAt': nowIso(),
      'expiresAt': optionalString(data['expiresAt'], 'expiresAt'),
    });

    return {
      'shortCode': code,
      'url': '${Env.publicCheckoutBaseUrl}/checkout?c=$code',
    };
  }

  Future<List<Map<String, dynamic>>> list(String orgId) async {
    final snap =
        await ctx.paymentLinks.where('orgId', '==', orgId).get();
    final list = snap.docs.map((d) => <String, dynamic>{'id': d.id, ...?d.data()}).toList();
    list.sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    return list;
  }

  /// Public lookup by short code (used by the hosted checkout page). Returns
  /// null if missing/inactive/expired.
  Future<Map<String, dynamic>?> resolveActive(String code) async {
    final snap = await ctx.paymentLinks.doc(code).get();
    if (!snap.exists) return null;
    final data = snap.data() ?? const {};
    if (data['active'] != true) return null;
    final expiresAt = data['expiresAt'] as String?;
    if (expiresAt != null && expiresAt.compareTo(nowIso()) < 0) return null;
    return {'id': snap.id, ...data};
  }

  Future<void> setActive(String orgId, String code, bool active) async {
    final snap = await ctx.paymentLinks.doc(code).get();
    if (!snap.exists) notFound('Payment link not found');
    if (snap.data()?['orgId'] != orgId) {
      forbidden('Payment link does not belong to your organization');
    }
    await ctx.paymentLinks.doc(code).update({'active': active});
  }

  Future<void> recordClick(String code) async {
    final ref = ctx.paymentLinks.doc(code);
    await ctx.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final clicks = (snap.data()?['clickCount'] as num?) ?? 0;
      tx.update(ref, {'clickCount': clicks + 1});
    });
  }
}
