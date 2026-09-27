import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/event_service.dart';
import '../utils/auth_context.dart';
import '../utils/validation.dart';
import 'common.dart';

/// Event (cause/collection) routes.
Router eventRoutes(EventService events) {
  final router = Router();

  router.post('/createEvent', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    return ok(await events.create(caller.orgId, await reqData(request)));
  });

  router.post('/getEvent', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['eventId'], 'eventId');
    return ok(await events.get(caller.orgId, id));
  });

  router.post('/listEvents', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final status = optionalString(data['status'], 'status');
    return items(await events.list(caller.orgId, status: status));
  });

  router.post('/updateEvent', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['eventId'], 'eventId');
    return ok(await events.update(caller.orgId, id, data));
  });

  router.post('/eventAnalytics', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['eventId'], 'eventId');
    return ok(await events.analytics(caller.orgId, id));
  });

  return router;
}
