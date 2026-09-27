import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/member_service.dart';
import '../utils/auth_context.dart';
import '../utils/validation.dart';
import 'common.dart';

/// Member (contributor) directory routes.
Router memberRoutes(MemberService members) {
  final router = Router();

  router.post('/createMember', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    return ok(await members.create(caller.orgId, await reqData(request)));
  });

  router.post('/getMember', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['memberId'], 'memberId');
    return ok(await members.get(caller.orgId, id));
  });

  router.post('/listMembers', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final limit = (data['limit'] as num?)?.toInt() ?? 100;
    return items(await members.list(caller.orgId, limit: limit));
  });

  router.post('/updateMember', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['memberId'], 'memberId');
    return ok(await members.update(caller.orgId, id, data));
  });

  router.post('/deleteMember', (Request request) async {
    final caller = requireAdmin(getTokenClaims(request));
    final data = await reqData(request);
    final id = requireString(data['memberId'], 'memberId');
    await members.remove(caller.orgId, id);
    return ok({'memberId': id, 'removed': true});
  });

  router.post('/topContributors', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final limit = (data['limit'] as num?)?.toInt() ?? 10;
    return items(await members.topContributors(caller.orgId, limit: limit));
  });

  router.post('/inactiveMembers', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final sinceDays = (data['sinceDays'] as num?)?.toInt() ?? 30;
    return items(await members.inactive(caller.orgId, sinceDays: sinceDays));
  });

  router.post('/importMembers', (Request request) async {
    final caller = requireCaller(getTokenClaims(request));
    final data = await reqData(request);
    final csv = requireString(data['csv'], 'csv');
    return ok(await members.bulkImport(caller.orgId, csv));
  });

  return router;
}
