import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../utils/errors.dart';

/// Shared helpers for shelf route handlers.

/// Parse the JSON body of a shelf request into a String-keyed map.
Future<Map<String, dynamic>> reqData(Request request) async {
  final body = await request.readAsString();
  if (body.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry('$k', v));
    }
  } catch (_) {
    // Fall through to empty map.
  }
  return <String, dynamic>{};
}

/// Get the verified token claims attached to the request by the auth
/// middleware. Throws 401 if missing.
Map<String, dynamic> getTokenClaims(Request request) {
  final claims = request.context['tokenClaims'];
  if (claims is! Map<String, dynamic>) {
    throw ApiException(401, 'Authentication required');
  }
  return claims;
}

/// JSON success response with a data payload.
Response ok(Map<String, dynamic> data) => Response.ok(
      jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

/// JSON success response wrapping a list in an envelope.
Response items(List<Map<String, dynamic>> list) => Response.ok(
      jsonEncode({'items': list, 'count': list.length}),
      headers: {'content-type': 'application/json'},
    );

/// JSON error response.
Response errorResponse(int status, String message) => Response(
      status,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );
