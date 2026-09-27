import 'errors.dart';

/// Lightweight request-payload validation helpers. Callables receive an
/// untyped `Map<String, dynamic>`; these coerce/validate fields and throw a
/// `bad-request` HttpResponseException on invalid input.

String requireString(dynamic value, String field) {
  if (value is! String || value.trim().isEmpty) {
    badRequest("'$field' must be a non-empty string");
  }
  return (value).trim();
}

String? optionalString(dynamic value, String field) {
  if (value == null || (value is String && value.trim().isEmpty)) return null;
  if (value is! String) badRequest("'$field' must be a string");
  return (value).trim();
}

num requireNumber(dynamic value, String field) {
  final n = value is String ? num.tryParse(value) : value;
  if (n is! num || n.isNaN || n.isInfinite) {
    badRequest("'$field' must be a number");
  }
  return n;
}

/// Daraja STK Push works in whole KES.
int requirePositiveAmount(dynamic value, [String field = 'amount']) {
  final n = requireNumber(value, field);
  if (n <= 0) badRequest("'$field' must be greater than zero");
  if (n != n.roundToDouble()) {
    badRequest("'$field' must be a whole number of KES");
  }
  return n.toInt();
}

String requireEnum(dynamic value, List<String> allowed, String field) {
  if (value is! String || !allowed.contains(value)) {
    badRequest("'$field' must be one of: ${allowed.join(', ')}");
  }
  return value;
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Create a URL-safe slug from a name.
String slugify(String input) {
  var s = input
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (s.length > 60) s = s.substring(0, 60);
  return s.replaceAll(RegExp(r'-+$'), '');
}

/// Generate a short, URL-friendly random code (for payment links).
String randomCode([int length = 7]) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final now = DateTime.now().microsecondsSinceEpoch;
  final buf = StringBuffer();
  var seed = now;
  for (var i = 0; i < length; i++) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    buf.write(chars[seed % chars.length]);
  }
  return buf.toString();
}
