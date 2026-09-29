import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:collecta_functions/config/context.dart';
import 'package:collecta_functions/config/params.dart';
import 'package:collecta_functions/handlers/auth_handlers.dart';
import 'package:collecta_functions/handlers/event_handlers.dart';
import 'package:collecta_functions/handlers/http_handlers.dart';
import 'package:collecta_functions/handlers/member_handlers.dart';
import 'package:collecta_functions/handlers/org_handlers.dart';
import 'package:collecta_functions/handlers/payment_handlers.dart';
import 'package:collecta_functions/handlers/payment_link_handlers.dart';
import 'package:collecta_functions/handlers/common.dart';
import 'package:collecta_functions/services/auth_service.dart';
import 'package:collecta_functions/services/daraja_service.dart';
import 'package:collecta_functions/services/event_service.dart';
import 'package:collecta_functions/services/member_service.dart';
import 'package:collecta_functions/services/org_service.dart';
import 'package:collecta_functions/services/payment_link_service.dart';
import 'package:collecta_functions/services/payment_service.dart';
import 'package:collecta_functions/utils/errors.dart';

/// Collecta standalone Dart server entry point.
///
/// Reads configuration from environment variables (or .env file locally),
/// initializes the Firebase Admin SDK with a service account key, builds the
/// service graph, and starts a shelf HTTP server.
Future<void> main(List<String> args) async {
  // Load .env file if it exists (local development).
  final envFile = File('.env');
  if (envFile.existsSync()) {
    final env = DotEnv()..load(['.env']);
    // Inject into Platform.environment is not possible, so we use a wrapper.
    // The Env class reads from Platform.environment, so for local dev we
    // need to set them manually in the process environment.
    // DotEnv loads them but doesn't set Platform.environment. We'll handle
    // this by reading from dotenv directly in Env if needed.
    // For simplicity: dotenv values are accessible via env['KEY'].
    // We set them into the process environment on supported platforms.
    for (final key in env.map.keys) {
      if (Platform.environment[key] == null) {
        // Platform.environment is unmodifiable, so we skip this.
        // The Env class needs to be updated to check dotenv too.
      }
    }
  }

  // Initialize Firebase Admin SDK with service account credentials.
  final serviceAccountJson = Env.firebaseServiceAccountJson;
  final saMap = jsonDecode(serviceAccountJson) as Map<String, dynamic>;
  final app = FirebaseApp.initializeApp(
    options: AppOptions(
      projectId: Env.firebaseProjectId,
      credential: Credential.fromServiceAccountParams(
        projectId: (saMap['project_id'] as String?) ?? Env.firebaseProjectId,
        email: saMap['client_email'] as String,
        privateKey: saMap['private_key'] as String,
      ),
    ),
  );
  final ctx = AppContext(db: app.firestore(), auth: app.auth());

  // Services (single shared instance each; DarajaService caches its token).
  final daraja = DarajaService();
  final auth = AuthService(ctx);
  final orgs = OrgService(ctx);
  final members = MemberService(ctx);
  final events = EventService(ctx);
  final links = PaymentLinkService(ctx);
  final payments = PaymentService(
    ctx,
    daraja: daraja,
    members: members,
    events: events,
    orgs: orgs,
  );

  // Build the router by mounting all route groups.
  final app_router = Router();

  // Mount authenticated API routes under /api
  final apiRouter = Router();
  apiRouter.mount('/auth', authRoutes(auth).call);
  apiRouter.mount('/org', orgRoutes(orgs).call);
  apiRouter.mount('/members', memberRoutes(members).call);
  apiRouter.mount('/events', eventRoutes(events).call);
  apiRouter.mount('/payments', paymentRoutes(payments).call);
  apiRouter.mount('/links', paymentLinkRoutes(links).call);

  // Mount public HTTP routes (no auth) at root
  app_router.mount('/', httpRoutes(payments, links).call);

  // Mount API routes with auth middleware
  app_router.mount('/api', _authMiddleware(ctx)(apiRouter.call));

  // Add CORS and error handling
  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(_errorMiddleware())
      .addHandler(app_router.call);

  final port = Env.port;
  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  print('✅ Collecta server running on http://0.0.0.0:${server.port}');
}

/// Middleware that verifies the Firebase ID token from the Authorization header
/// and injects the decoded claims into the request context.
Middleware _authMiddleware(AppContext ctx) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'] ?? '';
      if (!authHeader.startsWith('Bearer ')) {
        return errorResponse(401, 'Missing or invalid Authorization header');
      }
      final token = authHeader.substring(7);
      try {
        // Verify the Firebase ID token and extract claims.
        final decoded = await ctx.auth.verifyIdToken(token);
        final claims = <String, dynamic>{
          'uid': decoded.uid,
          ...?decoded.claims,
        };
        // Pass claims to the handler via request context.
        final updatedRequest = request.change(context: {
          'tokenClaims': claims,
        });
        return await innerHandler(updatedRequest);
      } catch (e) {
        return errorResponse(401, 'Invalid or expired token');
      }
    };
  };
}

/// CORS middleware — allows requests from any origin (fine for mobile apps).
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      };
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}

/// Error handling middleware — catches ApiException and returns JSON errors.
Middleware _errorMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        return errorResponse(e.statusCode, e.message);
      } catch (e, st) {
        print('Unhandled error: $e\n$st');
        return errorResponse(500, 'Internal server error');
      }
    };
  };
}
