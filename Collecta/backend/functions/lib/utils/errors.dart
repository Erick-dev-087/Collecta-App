/// HTTP error exception used by services and handlers. Shelf middleware
/// catches these and maps them to the correct HTTP status code + JSON body.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

Never badRequest(String message) => throw ApiException(400, message);

Never unauthorized(String message) => throw ApiException(401, message);

Never forbidden(String message) => throw ApiException(403, message);

Never notFound(String message) => throw ApiException(404, message);

Never conflict(String message) => throw ApiException(409, message);

Never failedPrecondition(String message) => throw ApiException(400, message);

Never internal(String message) => throw ApiException(500, message);
