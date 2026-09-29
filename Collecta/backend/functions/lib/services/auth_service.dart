import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import '../config/context.dart';
import '../constants/enums.dart';
import '../utils/errors.dart';
import '../utils/validation.dart';

/// AuthService handles the server-side parts of authentication that Firebase
/// Auth itself does not: creating the owning organization at sign-up, mirroring
/// a user profile document, and minting the custom claims ({ orgId, role })
/// that Firestore security rules and callables rely on.
///
/// Sign-up / login / password reset are performed by the Flutter app directly
/// against the Firebase Auth SDK.
class AuthService {
  AuthService(this.ctx);
  final AppContext ctx;

  /// Called immediately after a new admin creates their Firebase Auth account.
  /// Idempotently refuses if the user already belongs to an organization.
  Future<Map<String, dynamic>> bootstrapOrganization({
    required String uid,
    required String email,
    required String fullName,
    required String organizationName,
    String? phone,
  }) async {
    final name = requireString(organizationName, 'organizationName');

    final existing = await ctx.users.doc(uid).get();
    if (existing.exists && (existing.data()?['orgId'] as String?) != null) {
      conflict('User already belongs to an organization');
    }

    final orgId = newId();

    // Ensure a unique slug.
    var slug = slugify(name);
    if (slug.isEmpty) slug = 'org';
    final clash =
        await ctx.organizations.where('slug', WhereFilter.equal, slug).limit(1).get();
    if (clash.docs.isNotEmpty) slug = '$slug-${orgId.substring(0, 5).toLowerCase()}';

    final ts = nowIso();
    await ctx.organizations.doc(orgId).set({
      'name': name,
      'slug': slug,
      'description': '',
      'branding': <String, dynamic>{},
      'ownerId': uid,
      'createdAt': ts,
      'updatedAt': ts,
    });
    await ctx.users.doc(uid).set({
      'uid': uid,
      'orgId': orgId,
      'email': requireString(email, 'email'),
      'fullName': requireString(fullName, 'fullName'),
      'phone': optionalString(phone, 'phone'),
      'role': UserRole.admin,
      'createdAt': ts,
    });

    // Custom claims drive security rules + role checks on every later request.
    await ctx.auth.setCustomUserClaims(uid, customUserClaims: {
      'orgId': orgId,
      'role': UserRole.admin,
    });

    return {'orgId': orgId, 'slug': slug, 'role': UserRole.admin};
  }

  /// Attach an additional staff user (who has already signed up) to an org.
  Future<Map<String, dynamic>> addStaff({
    required String orgId,
    required String email,
    required String fullName,
    required String role,
  }) async {
    final org = await ctx.organizations.doc(orgId).get();
    if (!org.exists) notFound('Organization not found');
    final normalizedRole = requireEnum(role, UserRole.all, 'role');

    dynamic userRecord;
    try {
      userRecord = await ctx.auth.getUserByEmail(requireString(email, 'email'));
    } catch (_) {
      badRequest('User must sign up (create an account) before being added');
    }
    final uid = userRecord.uid as String;

    await ctx.users.doc(uid).set({
      'uid': uid,
      'orgId': orgId,
      'email': email,
      'fullName': requireString(fullName, 'fullName'),
      'role': normalizedRole,
      'createdAt': nowIso(),
    });
    await ctx.auth.setCustomUserClaims(uid, customUserClaims: {
      'orgId': orgId,
      'role': normalizedRole,
    });
    return {'uid': uid, 'role': normalizedRole};
  }

  Future<Map<String, dynamic>> getProfile(String uid) async {
    final snap = await ctx.users.doc(uid).get();
    if (!snap.exists) notFound('User profile not found');
    return {'id': snap.id, ...?snap.data()};
  }
}
