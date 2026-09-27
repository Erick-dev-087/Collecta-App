import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/params.dart';
import '../utils/errors.dart';

/// Parameters for an STK Push request.
class StkPushParams {
  StkPushParams({
    required this.amount,
    required this.phone,
    required this.shortcode,
    required this.passkey,
    required this.accountReference,
    required this.description,
    required this.callbackUrl,
    this.transactionType = 'CustomerPayBillOnline',
  });
  final int amount;
  final String phone; // MSISDN 2547XXXXXXXX
  final String shortcode;
  final String passkey;
  final String accountReference;
  final String description;
  final String callbackUrl;
  final String transactionType; // CustomerPayBillOnline | CustomerBuyGoodsOnline
}

class StkPushResult {
  StkPushResult({
    required this.merchantRequestId,
    required this.checkoutRequestId,
    required this.responseCode,
    required this.responseDescription,
    required this.customerMessage,
  });
  final String merchantRequestId;
  final String checkoutRequestId;
  final String responseCode;
  final String responseDescription;
  final String customerMessage;
}

/// Parsed asynchronous STK callback (Body.stkCallback).
class StkCallback {
  StkCallback({
    required this.resultCode,
    required this.resultDesc,
    this.merchantRequestId,
    this.checkoutRequestId,
    this.amount,
    this.mpesaReceiptNumber,
    this.transactionDate,
    this.phoneNumber,
  });
  final int resultCode;
  final String resultDesc;
  final String? merchantRequestId;
  final String? checkoutRequestId;
  final num? amount;
  final String? mpesaReceiptNumber;
  final String? transactionDate;
  final String? phoneNumber;

  bool get isSuccess => resultCode == 0;
}

// APPEND_MARKER

String _base64(String s) => base64.encode(utf8.encode(s));

/// Daraja timestamp: YYYYMMDDHHmmss in East Africa Time (UTC+3).
String _timestamp([DateTime? now]) {
  final eat = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 3));
  String p(int n) => n.toString().padLeft(2, '0');
  return '${eat.year}${p(eat.month)}${p(eat.day)}'
      '${p(eat.hour)}${p(eat.minute)}${p(eat.second)}';
}

/// Thin client over Safaricom's Daraja (M-Pesa Express) API. Caches the OAuth
/// token, initiates STK pushes, and queries STK status. When [darajaMock] is
/// enabled it returns deterministic fake identifiers so the whole payment flow
/// can be exercised without live credentials or a callback tunnel.
class DarajaService {
  String? _token;
  DateTime? _tokenExpiry;

  Future<String> _accessToken() async {
    if (_token != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      return _token!;
    }
    final creds = _base64('${Env.darajaConsumerKey}:${Env.darajaConsumerSecret}');
    final uri = Uri.parse(
      '${Env.darajaBaseUrl}/oauth/v1/generate?grant_type=client_credentials',
    );
    final res = await http.get(uri, headers: {'Authorization': 'Basic $creds'});
    if (res.statusCode != 200) {
      internal('Failed to obtain Daraja access token: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    _token = body['access_token'] as String;
    final ttl = int.tryParse('${body['expires_in'] ?? 3599}') ?? 3599;
    _tokenExpiry = DateTime.now().add(Duration(seconds: ttl));
    return _token!;
  }

  Future<StkPushResult> stkPush(StkPushParams p) async {
    if (Env.darajaMock) {
      final suffix = DateTime.now().millisecondsSinceEpoch;
      return StkPushResult(
        merchantRequestId: 'mock-merchant-$suffix',
        checkoutRequestId: 'ws_CO_mock_$suffix',
        responseCode: '0',
        responseDescription: 'Success. Request accepted for processing (mock)',
        customerMessage: 'Success. Request accepted for processing (mock)',
      );
    }

    final ts = _timestamp();
    final password = _base64('${p.shortcode}${p.passkey}$ts');
    final ref = p.accountReference.length > 12
        ? p.accountReference.substring(0, 12)
        : p.accountReference;
    final desc = p.description.isEmpty
        ? 'Payment'
        : (p.description.length > 13 ? p.description.substring(0, 13) : p.description);

    final payload = {
      'BusinessShortCode': p.shortcode,
      'Password': password,
      'Timestamp': ts,
      'TransactionType': p.transactionType,
      'Amount': p.amount,
      'PartyA': p.phone,
      'PartyB': p.shortcode,
      'PhoneNumber': p.phone,
      'CallBackURL': p.callbackUrl,
      'AccountReference': ref,
      'TransactionDesc': desc,
    };

    final token = await _accessToken();
    final res = await http.post(
      Uri.parse('${Env.darajaBaseUrl}/mpesa/stkpush/v1/processrequest'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    final body = _decode(res.body);
    if (res.statusCode != 200 || '${body['ResponseCode']}' != '0') {
      internal('STK Push failed: ${res.body}');
    }
    return StkPushResult(
      merchantRequestId: '${body['MerchantRequestID']}',
      checkoutRequestId: '${body['CheckoutRequestID']}',
      responseCode: '${body['ResponseCode']}',
      responseDescription: '${body['ResponseDescription']}',
      customerMessage: '${body['CustomerMessage']}',
    );
  }

  /// Query the status of a previously initiated STK push. Returns the Daraja
  /// ResultCode (0 = success) and description.
  Future<({int resultCode, String resultDesc})> queryStk({
    required String checkoutRequestId,
    required String shortcode,
    required String passkey,
  }) async {
    if (Env.darajaMock) {
      return (resultCode: 0, resultDesc: 'Processed successfully (mock)');
    }
    final ts = _timestamp();
    final password = _base64('$shortcode$passkey$ts');
    final token = await _accessToken();
    final res = await http.post(
      Uri.parse('${Env.darajaBaseUrl}/mpesa/stkpushquery/v1/query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'BusinessShortCode': shortcode,
        'Password': password,
        'Timestamp': ts,
        'CheckoutRequestID': checkoutRequestId,
      }),
    );
    final body = _decode(res.body);
    return (
      resultCode: int.tryParse('${body['ResultCode']}') ?? -1,
      resultDesc: '${body['ResultDesc'] ?? 'unknown'}',
    );
  }

  /// Parse the asynchronous STK callback payload posted by Safaricom.
  static StkCallback parseCallback(Map<String, dynamic> jsonBody) {
    final cb = (jsonBody['Body'] as Map?)?['stkCallback'] as Map?;
    if (cb == null) badRequest('Malformed Daraja callback payload');
    final items = (cb['CallbackMetadata'] as Map?)?['Item'] as List? ?? const [];
    dynamic itemValue(String name) {
      for (final it in items) {
        if (it is Map && it['Name'] == name) return it['Value'];
      }
      return null;
    }

    return StkCallback(
      merchantRequestId: cb['MerchantRequestID']?.toString(),
      checkoutRequestId: cb['CheckoutRequestID']?.toString(),
      resultCode: int.tryParse('${cb['ResultCode']}') ?? -1,
      resultDesc: '${cb['ResultDesc'] ?? ''}',
      amount: itemValue('Amount') is num ? itemValue('Amount') as num : null,
      mpesaReceiptNumber: itemValue('MpesaReceiptNumber')?.toString(),
      transactionDate: itemValue('TransactionDate')?.toString(),
      phoneNumber: itemValue('PhoneNumber')?.toString(),
    );
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

