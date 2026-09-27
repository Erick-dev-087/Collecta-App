import '../constants/enums.dart';
import 'errors.dart';

/// The authenticated caller's context, derived from the verified Firebase ID
/// token's custom claims ({ orgId, role }).
class Caller {
  Caller({required this.uid, required this.orgId, required this.role});

  final String uid;
  final String orgId;
  final String role;

  bool get isAdmin => role == UserRole.admin;
}

/// Validate that the caller has an orgId claim. Throws if not.
Caller requireCaller(Map<String, dynamic> token) {
  final uid = token['uid'] as String?;
  if (uid == null || uid.isEmpty) {
    unauthorized('Authentication required');
  }
  final orgId = token['orgId'];
  final role = token['role'];
  if (orgId is! String || orgId.isEmpty) {
    failedPrecondition('User is not attached to an organization');
  }
  return Caller(
    uid: uid,
    orgId: orgId,
    role: role is String ? role : UserRole.manager,
  );
}

/// Like [requireCaller] but additionally requires the admin role.
Caller requireAdmin(Map<String, dynamic> token) {
  final caller = requireCaller(token);
  if (!caller.isAdmin) {
    forbidden('This action requires an admin role');
  }
  return caller;
}

/// The bare uid for endpoints used before an org exists (e.g. bootstrap).
String requireUid(Map<String, dynamic> token) {
  final uid = token['uid'] as String?;
  if (uid == null || uid.isEmpty) unauthorized('Authentication required');
  return uid;
}
