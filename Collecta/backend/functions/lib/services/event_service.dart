import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import '../config/context.dart';
import '../constants/enums.dart';
import '../utils/errors.dart';
import '../utils/validation.dart';

/// EventService: causes/collections created by an organization. Aggregates
/// (totalCollected, paymentCount) are maintained server-side via
/// [applyCompletedPayment].
class EventService {
  EventService(this.ctx);
  final AppContext ctx;

  Future<Map<String, dynamic>> create(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    final title = requireString(data['title'], 'title');
    final id = newId();
    final ts = nowIso();
    await ctx.events(orgId).doc(id).set({
      'orgId': orgId,
      'title': title,
      'description': optionalString(data['description'], 'description'),
      'eventDate': optionalString(data['eventDate'], 'eventDate'),
      'defaultAmount':
          data['defaultAmount'] == null ? null : requirePositiveAmount(data['defaultAmount'], 'defaultAmount'),
      'targetAmount':
          data['targetAmount'] == null ? null : requirePositiveAmount(data['targetAmount'], 'targetAmount'),
      'allowCustomAmount': asBool(data['allowCustomAmount'], true),
      'status': EventStatus.draft,
      'imageUrl': optionalString(data['imageUrl'], 'imageUrl'),
      'galleryUrls': <String>[],
      'totalCollected': 0,
      'paymentCount': 0,
      'createdAt': ts,
      'updatedAt': ts,
    });
    return {'id': id};
  }

  Future<Map<String, dynamic>> get(String orgId, String eventId) async {
    final snap = await ctx.events(orgId).doc(eventId).get();
    if (!snap.exists) notFound('Event not found');
    return {'id': snap.id, ...?snap.data()};
  }

  Future<List<Map<String, dynamic>>> list(String orgId, {String? status}) async {
    final snap = await ctx.events(orgId).get();
    var list = snap.docs.map((d) => <String, dynamic>{'id': d.id, ...?d.data()}).toList();
    if (status != null) {
      list = list.where((e) => e['status'] == status).toList();
    }
    list.sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    return list;
  }

  Future<Map<String, dynamic>> update(
    String orgId,
    String eventId,
    Map<String, dynamic> data,
  ) async {
    final update = <String, dynamic>{'updatedAt': nowIso()};
    for (final key in ['title', 'description', 'eventDate', 'imageUrl']) {
      final v = optionalString(data[key], key);
      if (v != null) update[key] = v;
    }
    if (data['defaultAmount'] != null) {
      update['defaultAmount'] = requirePositiveAmount(data['defaultAmount'], 'defaultAmount');
    }
    if (data['targetAmount'] != null) {
      update['targetAmount'] = requirePositiveAmount(data['targetAmount'], 'targetAmount');
    }
    if (data['allowCustomAmount'] != null) {
      update['allowCustomAmount'] = asBool(data['allowCustomAmount']);
    }
    if (data['status'] != null) {
      update['status'] = requireEnum(data['status'], EventStatus.all, 'status');
    }
    await ctx.events(orgId).doc(eventId).update(update);
    return get(orgId, eventId);
  }

  /// Analytics: collections + paid/pending breakdown for an event.
  Future<Map<String, dynamic>> analytics(String orgId, String eventId) async {
    final event = await get(orgId, eventId);
    final paymentsSnap =
        await ctx.payments.where('eventId', '==', eventId).get();

    num totalCollected = 0;
    var completed = 0, pending = 0, failed = 0;
    final contributors = <String>{};
    for (final d in paymentsSnap.docs) {
      final p = d.data() ?? const {};
      switch (p['status']) {
        case PaymentStatus.completed:
          completed++;
          totalCollected += (p['amount'] as num?) ?? 0;
          if (p['memberId'] != null) contributors.add('${p['memberId']}');
          break;
        case PaymentStatus.initiated:
        case PaymentStatus.pending:
          pending++;
          break;
        case PaymentStatus.failed:
        case PaymentStatus.cancelled:
          failed++;
          break;
      }
    }

    final target = (event['targetAmount'] as num?);
    return {
      'eventId': eventId,
      'title': event['title'],
      'targetAmount': target,
      'totalCollected': totalCollected,
      'progress': (target != null && target > 0)
          ? (totalCollected / target).clamp(0, 1)
          : null,
      'completedPayments': completed,
      'pendingPayments': pending,
      'failedPayments': failed,
      'uniqueContributors': contributors.length,
    };
  }

  /// Atomically fold a completed payment into the event aggregates.
  Future<void> applyCompletedPayment(
    String orgId,
    String eventId,
    num amount,
  ) async {
    final ref = ctx.events(orgId).doc(eventId);
    await ctx.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? const {};
      tx.update(ref, {
        'totalCollected': ((data['totalCollected'] as num?) ?? 0) + amount,
        'paymentCount': ((data['paymentCount'] as num?) ?? 0) + 1,
        'updatedAt': nowIso(),
      });
    });
  }
}
