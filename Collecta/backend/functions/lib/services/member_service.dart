import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import '../config/context.dart';
import '../utils/csv.dart';
import '../utils/errors.dart';
import '../utils/phone.dart';
import '../utils/validation.dart';

/// MemberService: the organization's contributor directory. Aggregate fields
/// (totalContributed, contributionCount, lastContributionAt) are owned by the
/// server and updated via [applyContribution] when a payment completes.
class MemberService {
  MemberService(this.ctx);
  final AppContext ctx;

  Future<Map<String, dynamic>> create(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    final fullName = requireString(data['fullName'], 'fullName');
    final phone = normalizePhone(requireString(data['phone'], 'phone'));

    final existing = await ctx
        .members(orgId)
        .where('phone', WhereFilter.equal, phone)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      conflict('A member with this phone number already exists');
    }

    final id = newId();
    final ts = nowIso();
    await ctx.members(orgId).doc(id).set({
      'fullName': fullName,
      'phone': phone,
      'email': optionalString(data['email'], 'email'),
      'gender': optionalString(data['gender'], 'gender'),
      'totalContributed': 0,
      'contributionCount': 0,
      'lastContributionAt': null,
      'createdAt': ts,
      'updatedAt': ts,
    });
    return {'id': id, 'phone': phone};
  }

  // APPEND_MARKER

  Future<Map<String, dynamic>> get(String orgId, String memberId) async {
    final snap = await ctx.members(orgId).doc(memberId).get();
    if (!snap.exists) notFound('Member not found');
    return {'id': snap.id, ...?snap.data()};
  }

  /// List members ordered by name. [limit] caps the page size; [after] is the
  /// last member id from the previous page for simple cursoring (optional).
  Future<List<Map<String, dynamic>>> list(String orgId, {int limit = 100}) async {
    final snap = await ctx.members(orgId).limit(limit).get();
    final list =
        snap.docs.map((d) => <String, dynamic>{'id': d.id, ...?d.data()}).toList();
    list.sort((a, b) =>
        '${a['fullName']}'.toLowerCase().compareTo('${b['fullName']}'.toLowerCase()));
    return list;
  }

  Future<Map<String, dynamic>> update(
    String orgId,
    String memberId,
    Map<String, dynamic> data,
  ) async {
    final update = <String, dynamic>{'updatedAt': nowIso()};
    final fullName = optionalString(data['fullName'], 'fullName');
    if (fullName != null) update['fullName'] = fullName;
    final email = optionalString(data['email'], 'email');
    if (email != null) update['email'] = email;
    final gender = optionalString(data['gender'], 'gender');
    if (gender != null) update['gender'] = gender;
    if (data['phone'] != null) {
      update['phone'] = normalizePhone(requireString(data['phone'], 'phone'));
    }
    await ctx.members(orgId).doc(memberId).update(update);
    return get(orgId, memberId);
  }

  Future<void> remove(String orgId, String memberId) async {
    await ctx.members(orgId).doc(memberId).delete();
  }

  /// Top contributors by total amount contributed.
  Future<List<Map<String, dynamic>>> topContributors(
    String orgId, {
    int limit = 10,
  }) async {
    final snap = await ctx
        .members(orgId)
        .orderBy('totalContributed', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => <String, dynamic>{'id': d.id, ...?d.data()}).toList();
  }

  /// Members who have not contributed since [sinceDays] ago (or never).
  Future<List<Map<String, dynamic>>> inactive(
    String orgId, {
    int sinceDays = 30,
  }) async {
    final cutoff = isoMinutesAgo(sinceDays * 24 * 60);
    final snap = await ctx.members(orgId).get();
    final result = <Map<String, dynamic>>[];
    for (final d in snap.docs) {
      final last = d.data()?['lastContributionAt'] as String?;
      if (last == null || last.compareTo(cutoff) < 0) {
        result.add({'id': d.id, ...?d.data()});
      }
    }
    return result;
  }

  /// Bulk-import members from CSV content. Skips duplicates (by phone) and
  /// invalid rows, reporting counts. Uses a batched write.
  Future<Map<String, dynamic>> bulkImport(String orgId, String csvContent) async {
    final rows = parseMembersCsv(csvContent);

    // Existing phones to skip duplicates.
    final existing = await ctx.members(orgId).get();
    final knownPhones = <String>{
      for (final d in existing.docs)
        if (d.data()?['phone'] is String) d.data()!['phone'] as String,
    };

    var imported = 0;
    var skipped = 0;
    final errors = <String>[];
    var batch = ctx.db.batch();
    var pending = 0;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      String phone;
      try {
        phone = normalizePhone(row.phone);
      } catch (_) {
        skipped++;
        errors.add('Row ${i + 2}: invalid phone "${row.phone}"');
        continue;
      }
      if (knownPhones.contains(phone)) {
        skipped++;
        continue;
      }
      knownPhones.add(phone);
      final ts = nowIso();
      batch.set(ctx.members(orgId).doc(newId()), {
        'fullName': row.fullName,
        'phone': phone,
        'email': row.email,
        'gender': row.gender,
        'totalContributed': 0,
        'contributionCount': 0,
        'lastContributionAt': null,
        'createdAt': ts,
        'updatedAt': ts,
      });
      imported++;
      pending++;
      // Firestore batches cap at 500 writes.
      if (pending >= 450) {
        await batch.commit();
        batch = ctx.db.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();

    return {
      'imported': imported,
      'skipped': skipped,
      'total': rows.length,
      'errors': errors,
    };
  }

  /// Find a member by phone within an org, or create a lightweight one
  /// (anonymous payer auto-registration). Returns the member id.
  Future<String> findOrCreateByPhone(
    String orgId,
    String phone, {
    String? name,
  }) async {
    final normalized = normalizePhone(phone);
    final existing = await ctx
        .members(orgId)
        .where('phone', WhereFilter.equal, normalized)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final id = newId();
    final ts = nowIso();
    await ctx.members(orgId).doc(id).set({
      'fullName': (name != null && name.trim().isNotEmpty) ? name.trim() : normalized,
      'phone': normalized,
      'email': null,
      'gender': null,
      'totalContributed': 0,
      'contributionCount': 0,
      'lastContributionAt': null,
      'autoCreated': true,
      'createdAt': ts,
      'updatedAt': ts,
    });
    return id;
  }

  /// Atomically add a completed contribution to a member's aggregates.
  Future<void> applyContribution(
    String orgId,
    String memberId,
    num amount,
  ) async {
    final ref = ctx.members(orgId).doc(memberId);
    await ctx.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? const {};
      final total = (data['totalContributed'] as num?) ?? 0;
      final count = (data['contributionCount'] as num?) ?? 0;
      tx.update(ref, {
        'totalContributed': total + amount,
        'contributionCount': count + 1,
        'lastContributionAt': nowIso(),
        'updatedAt': nowIso(),
      });
    });
  }

}
