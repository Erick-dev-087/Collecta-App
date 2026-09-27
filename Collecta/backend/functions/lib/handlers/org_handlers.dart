import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/org_service.dart';
import '../utils/auth_context.dart';
import '../utils/validation.dart';
import 'common.dart';

/// Organization profile/branding and M-Pesa payment-destination routes.
Router orgRoutes(OrgService orgs) {
  final router = Router();

  router.post('/getOrganization', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    return ok(await orgs.get(caller.orgId));
  });

  router.post('/updateOrganization', (Request request) async {
    final caller = requireAdmin(getTokenClaims(request));
    return ok(await orgs.updateProfile(caller.orgId, await reqData(request)));
  });

  router.post('/listPaymentDestinations', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    return items(await orgs.listDestinations(caller.orgId));
  });

  router.post('/addPaymentDestination', (Request request) async {
    final caller = requireAdmin(getTokenClaims(request));
    return ok(await orgs.addDestination(caller.orgId, await reqData(request)));
  });

  router.post('/setDefaultPaymentDestination', (Request request) async {
    final caller = requireAdmin(getTokenClaims(request));
    final data = await reqData(request);
    final destId = requireString(data['destinationId'], 'destinationId');
    await orgs.setDefaultDestination(caller.orgId, destId);
    return ok({'destinationId': destId, 'isDefault': true});
  });

  router.post('/removePaymentDestination', (Request request) async {
    final caller = requireAdmin(getTokenClaims(request));
    final data = await reqData(request);
    final destId = requireString(data['destinationId'], 'destinationId');
    await orgs.removeDestination(caller.orgId, destId);
    return ok({'destinationId': destId, 'removed': true});
  });

  return router;
}
