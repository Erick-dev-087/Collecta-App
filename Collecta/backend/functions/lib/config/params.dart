import 'dart:io';

/// Deploy-time / runtime parameters. All values come from environment
/// variables (set in .env locally, or in the Render dashboard for production).
///
/// Each getter reads from Platform.environment at call time so tests can
/// override via zone or by setting the env before calling.

class Env {
  Env._();

  static String _require(String key) {
    final v = Platform.environment[key];
    if (v == null || v.trim().isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }
    return v.trim();
  }

  static String _optional(String key, [String fallback = '']) =>
      Platform.environment[key]?.trim() ?? fallback;

  // --- Server ---------------------------------------------------------------
  static int get port => int.tryParse(_optional('PORT', '8080')) ?? 8080;

  // --- Firebase -------------------------------------------------------------
  static String get firebaseProjectId => _require('FIREBASE_PROJECT_ID');
  static String get firebaseServiceAccountJson =>
      _require('FIREBASE_SERVICE_ACCOUNT_JSON');

  // --- Daraja (M-Pesa) ------------------------------------------------------
  static String get darajaEnv => _optional('DARAJA_ENV', 'sandbox');
  static String get darajaConsumerKey => _require('DARAJA_CONSUMER_KEY');
  static String get darajaConsumerSecret => _require('DARAJA_CONSUMER_SECRET');
  static String get darajaShortcode => _optional('DARAJA_SHORTCODE', '174379');
  static String get darajaPasskey => _require('DARAJA_PASSKEY');
  static bool get darajaMock =>
      _optional('DARAJA_MOCK', 'false').toLowerCase() == 'true';

  // --- Public URLs -----------------------------------------------------------
  static String get publicCallbackBaseUrl =>
      _optional('PUBLIC_CALLBACK_BASE_URL');
  static String get publicCheckoutBaseUrl =>
      _optional('PUBLIC_CHECKOUT_BASE_URL');

  /// Resolved base URL for the Daraja REST API.
  static String get darajaBaseUrl => darajaEnv == 'production'
      ? 'https://api.safaricom.co.ke'
      : 'https://sandbox.safaricom.co.ke';
}
