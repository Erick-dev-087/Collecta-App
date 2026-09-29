import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import '../config/context.dart';
import '../constants/enums.dart';
import '../utils/errors.dart';
import '../utils/validation.dart';

/// Resolved STK Push destination for an organization.
class ResolvedDestination {
  ResolvedDestination({
    required this.type,
    required this.shortcode,
    this.passkey,
    this.accountNumber,
  });
  final String type;
  final String shortcode;
  final String? passkey; // null => use platform default (env)
  final String? accountNumber;

  String get transactionType => type == PaymentDestinationType.till
      ? 'CustomerBuyGoodsOnline'
      : 'CustomerPayBillOnline';
}

/// OrgService: organization profile/branding and M-Pesa payment destinations
/// (paybill/till shortcodes). Passkeys are never returned to clients.
class OrgService {
  OrgService(this.ctx);
  final AppContext ctx;

  Future<Map<String, dynamic>> get(String orgId) async {
    final snap = await ctx.organizations.doc(orgId).get();
    if (!snap.exists) notFound('Organization not found');
    return {'id': snap.id, ...?snap.data()};
  }

  Future<Map<String, dynamic>> updateProfile(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    final update = <String, dynamic>{'updatedAt': nowIso()};
    final name = optionalString(data['name'], 'name');
    if (name != null) update['name'] = name;
    final description = optionalString(data['description'], 'description');
    if (description != null) update['description'] = description;

    final primary = optionalString(data['primaryColor'], 'primaryColor');
    final secondary = optionalString(data['secondaryColor'], 'secondaryColor');
    final logo = optionalString(data['logoUrl'], 'logoUrl');
    // Merge branding sub-map (read-modify-write keeps other branding fields).
    if (primary != null || secondary != null || logo != null) {
      final current = await ctx.organizations.doc(orgId).get();
      final branding = Map<String, dynamic>.from(
          (current.data()?['branding'] as Map?) ?? const {});
      if (primary != null) branding['primaryColor'] = primary;
      if (secondary != null) branding['secondaryColor'] = secondary;
      if (logo != null) branding['logoUrl'] = logo;
      update['branding'] = branding;
    }

    await ctx.organizations.doc(orgId).update(update);
    return get(orgId);
  }

  // --- Payment destinations -------------------------------------------------

  Future<List<Map<String, dynamic>>> listDestinations(String orgId) async {
    final snap = await ctx.paymentDestinations(orgId).get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data() ?? const {});
      final hasPasskey = (data['passkey'] as String?)?.isNotEmpty ?? false;
      data.remove('passkey'); // never expose secrets
      return {'id': d.id, 'hasPasskey': hasPasskey, ...data};
    }).toList();
  }

  Future<Map<String, dynamic>> addDestination(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    final type = requireEnum(data['type'], PaymentDestinationType.all, 'type');
    final shortcode = requireString(data['shortcode'], 'shortcode');
    if (!RegExp(r'^\d{5,7}$').hasMatch(shortcode)) {
      badRequest('shortcode must be a 5-7 digit number');
    }
    final isDefault = asBool(data['isDefault']);
    final id = newId();

    await ctx.paymentDestinations(orgId).doc(id).set({
      'type': type,
      'shortcode': shortcode,
      'accountNumber': optionalString(data['accountNumber'], 'accountNumber'),
      'name': optionalString(data['name'], 'name'),
      'passkey': optionalString(data['passkey'], 'passkey'),
      'isActive': true,
      'isDefault': isDefault,
      'createdAt': nowIso(),
    });
    if (isDefault) await setDefaultDestination(orgId, id);
    return {'id': id};
  }

  /// Ensure exactly one active destination is flagged default.
  Future<void> setDefaultDestination(String orgId, String destId) async {
    final all = await ctx.paymentDestinations(orgId).get();
    final batch = ctx.db.batch();
    for (final d in all.docs) {
      // WriteBatch.update keys are FieldPaths (unlike Transaction/doc.update
      // which accept plain string keys).
      batch.update(ctx.paymentDestinations(orgId).doc(d.id), {
        FieldPath.from('isDefault'): d.id == destId,
      });
    }
    await batch.commit();
  }

  Future<void> removeDestination(String orgId, String destId) async {
    await ctx.paymentDestinations(orgId).doc(destId).delete();
  }

  /// Resolve which shortcode/passkey to use for an org's STK push. Returns null
  /// when the org has no destination configured (caller falls back to env
  /// platform defaults).
  Future<ResolvedDestination?> resolveDestination(String orgId) async {
    final snap = await ctx
        .paymentDestinations(orgId)
        .where('isActive', WhereFilter.equal, true)
        .get();
    if (snap.docs.isEmpty) return null;
    var chosen = snap.docs.first;
    for (final d in snap.docs) {
      if (d.data()?['isDefault'] == true) {
        chosen = d;
        break;
      }
    }
    final data = chosen.data() ?? const {};
    return ResolvedDestination(
      type: '${data['type'] ?? PaymentDestinationType.paybill}',
      shortcode: '${data['shortcode']}',
      passkey: (data['passkey'] as String?)?.isNotEmpty == true
          ? data['passkey'] as String
          : null,
      accountNumber: data['accountNumber'] as String?,
    );
  }
}
