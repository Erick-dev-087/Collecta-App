import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/auth_service.dart';
import '../utils/auth_context.dart';
import '../utils/validation.dart';
import 'common.dart';

/// Auth-related routes.
Router authRoutes(AuthService auth) {
  final router = Router();

  router.post('/bootstrapOrganization', (Request request) async {
    final token = getTokenClaims(request);
    final uid = requireUid(token);
    final data = await reqData(request);
    final result = await auth.bootstrapOrganization(
      uid: uid,
      email: requireString(data['email'], 'email'),
      fullName: requireString(data['fullName'], 'fullName'),
      organizationName: requireString(
        data['organizationName'],
        'organizationName',
      ),
      phone: optionalString(data['phone'], 'phone'),
    );
    return ok(result);
  });

  router.post('/addStaff', (Request request) async {
    final caller = requireAdmin(getTokenClaims(request));
    final data = await reqData(request);
    final result = await auth.addStaff(
      orgId: caller.orgId,
      email: requireString(data['email'], 'email'),
      fullName: requireString(data['fullName'], 'fullName'),
      role: requireString(data['role'], 'role'),
    );
    return ok(result);
  });

  router.post('/getProfile', (Request request) async {
    final uid = requireUid(getTokenClaims(request));
    return ok(await auth.getProfile(uid));
  });

  return router;
}
