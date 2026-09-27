import 'errors.dart';

/// Normalise a Kenyan phone number to Safaricom's MSISDN format
/// `2547XXXXXXXX` / `2541XXXXXXXX` (12 digits, no plus). Accepts the common
/// local formats: 07XXXXXXXX, 01XXXXXXXX, +2547XXXXXXXX, 2547XXXXXXXX,
/// 7XXXXXXXX / 1XXXXXXXX.
String normalizePhone(String raw) {
  if (raw.trim().isEmpty) badRequest('Phone number is required');
  var digits = raw.replaceAll(RegExp(r'[\s\-()+]'), '');

  if (RegExp(r'^0[17]\d{8}$').hasMatch(digits)) {
    digits = '254${digits.substring(1)}';
  } else if (RegExp(r'^[17]\d{8}$').hasMatch(digits)) {
    digits = '254$digits';
  } else if (RegExp(r'^254[17]\d{8}$').hasMatch(digits)) {
    // already normalised
  } else {
    badRequest('Invalid Kenyan phone number: $raw');
  }
  return digits;
}

bool isValidPhone(String raw) {
  try {
    normalizePhone(raw);
    return true;
  } catch (_) {
    return false;
  }
}
