import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/payment_link_service.dart';
import '../utils/auth_context.dart';
import '../utils/validation.dart';
import 'common.dart';

/// Payment-link routes.
Router paymentLinkRoutes(PaymentLinkService links) {
  final router = Router();

  router.post('/createPaymentLink', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    return ok(await links.create(
        caller.orgId, caller.uid, await reqData(request)));
  });

  router.post('/listPaymentLinks', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    return items(await links.list(caller.orgId));
  });

  router.post('/setPaymentLinkActive', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final code = requireString(data['shortCode'], 'shortCode');
    final active = asBool(data['active']);
    await links.setActive(caller.orgId, code, active);
    return ok({'shortCode': code, 'active': active});
  });

  return router;
}
