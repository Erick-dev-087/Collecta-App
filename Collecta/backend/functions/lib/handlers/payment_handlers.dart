import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/payment_service.dart';
import '../utils/auth_context.dart';
import '../utils/validation.dart';
import 'common.dart';

/// Payment routes. STK-push initiation and reconciliation talk to Daraja.
Router paymentRoutes(PaymentService payments) {
  final router = Router();

  router.post('/initiatePayment', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final result = await payments.initiate(
      orgId: caller.orgId,
      eventId: requireString(data['eventId'], 'eventId'),
      phone: requireString(data['phone'], 'phone'),
      amount: data['amount'] == null
          ? null
          : requirePositiveAmount(data['amount'], 'amount'),
      payerName: optionalString(data['payerName'], 'payerName'),
    );
    return ok(result);
  });

  router.post('/recordCash', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final result = await payments.recordCash(
      orgId: caller.orgId,
      eventId: requireString(data['eventId'], 'eventId'),
      phone: requireString(data['phone'], 'phone'),
      amount: requirePositiveAmount(data['amount'], 'amount'),
      payerName: optionalString(data['payerName'], 'payerName'),
    );
    return ok(result);
  });

  router.post('/getPaymentStatus', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['paymentId'], 'paymentId');
    return ok(await payments.getStatus(caller.orgId, id));
  });

  router.post('/paymentHistory', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final limit = (data['limit'] as num?)?.toInt() ?? 100;
    return items(await payments.history(
      caller.orgId,
      eventId: optionalString(data['eventId'], 'eventId'),
      limit: limit,
    ));
  });

  router.post('/listStuckPayments', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    return items(await payments.listStuck(caller.orgId));
  });

  router.post('/reconcilePayment', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['paymentId'], 'paymentId');
    return ok(await payments.reconcile(caller.orgId, id));
  });

  router.post('/exportPayments', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final csv = await payments.exportCsv(caller.orgId);
    return ok({'csv': csv, 'filename': 'payments-${caller.orgId}.csv'});
  });

  return router;
}
