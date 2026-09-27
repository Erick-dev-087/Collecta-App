import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config/params.dart';
import '../services/daraja_service.dart';
import '../services/payment_link_service.dart';
import '../services/payment_service.dart';

/// Public HTTP endpoints (no auth required):
///  - `POST /darajaCallback`  : Safaricom STK callback webhook.
///  - `GET  /checkout?c=<code>` : hosted checkout page.
///  - `POST /checkout?c=<code>` : initiates STK push from checkout.
Router httpRoutes(
  PaymentService payments,
  PaymentLinkService links,
) {
  final router = Router();

  // --- Daraja STK callback webhook ----------------------------------------
  router.post('/darajaCallback', (Request request) async {
    try {
      final raw = await request.readAsString();
      final body = raw.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(raw) as Map).cast<String, dynamic>();
      final cb = DarajaService.parseCallback(body);
      await payments.handleCallback(body, cb);
    } catch (e) {
      print('darajaCallback failed: $e');
    }
    return Response.ok(
      jsonEncode({'ResultCode': 0, 'ResultDesc': 'Accepted'}),
      headers: {'content-type': 'application/json'},
    );
  });

  // --- Hosted checkout page (payment short links) -------------------------
  router.get('/checkout', (Request request) async {
    final code = request.url.queryParameters['c'] ?? '';
    final link = code.isEmpty ? null : await links.resolveActive(code);
    if (link == null) {
      return Response.notFound(
        _page('Link unavailable',
            '<p class="msg">This payment link is invalid, inactive or expired.</p>'),
        headers: _htmlHeaders,
      );
    }
    await links.recordClick(code);
    return Response.ok(_checkoutForm(code, link), headers: _htmlHeaders);
  });

  router.post('/checkout', (Request request) async {
    final code = request.url.queryParameters['c'] ?? '';
    final link = code.isEmpty ? null : await links.resolveActive(code);
    if (link == null) {
      return Response.notFound(
        _page('Link unavailable',
            '<p class="msg">This payment link is invalid, inactive or expired.</p>'),
        headers: _htmlHeaders,
      );
    }

    final form = Uri.splitQueryString(await request.readAsString());
    final phone = (form['phone'] ?? '').trim();
    if (phone.isEmpty) {
      return Response.ok(
        _checkoutForm(code, link, error: 'Phone number is required.'),
        headers: _htmlHeaders,
      );
    }
    final fixedAmount = link['amount'] as num?;
    final allowCustom = link['allowCustomAmount'] == true;
    int? amount = fixedAmount?.toInt();
    if (allowCustom) {
      final entered = num.tryParse((form['amount'] ?? '').trim());
      if (entered == null || entered <= 0) {
        return Response.ok(
          _checkoutForm(code, link, error: 'Enter a valid amount.'),
          headers: _htmlHeaders,
        );
      }
      amount = entered.toInt();
    }
    try {
      final result = await payments.initiate(
        orgId: '${link['orgId']}',
        eventId: '${link['eventId']}',
        phone: phone,
        amount: amount,
        paymentLinkId: code,
      );
      return Response.ok(
        _page('Check your phone',
            '<p class="msg">${_esc('${result['customerMessage'] ?? 'An M-Pesa prompt has been sent to your phone. Enter your PIN to complete payment.'}')}</p>'),
        headers: _htmlHeaders,
      );
    } catch (e) {
      return Response.ok(
        _checkoutForm(code, link,
            error: 'Could not start the payment. Please try again.'),
        headers: _htmlHeaders,
      );
    }
  });

  // --- Health check ---------------------------------------------------------
  router.get('/health', (Request request) async {
    return Response.ok(
      jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}

const _htmlHeaders = {'content-type': 'text/html; charset=utf-8'};

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Minimal styled HTML shell.
String _page(String title, String body) => '''
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_esc(title)}</title>
<style>
  :root{font-family:system-ui,Segoe UI,Roboto,sans-serif}
  body{margin:0;background:#0f172a;color:#e2e8f0;display:flex;min-height:100vh;
    align-items:center;justify-content:center;padding:16px}
  .card{background:#1e293b;border-radius:16px;padding:28px;max-width:380px;width:100%;
    box-shadow:0 10px 40px rgba(0,0,0,.4)}
  h1{font-size:1.25rem;margin:0 0 4px}
  .amt{font-size:2rem;font-weight:700;color:#34d399;margin:12px 0}
  label{display:block;font-size:.8rem;margin:14px 0 6px;color:#94a3b8}
  input{width:100%;box-sizing:border-box;padding:12px;border-radius:10px;border:1px solid #334155;
    background:#0f172a;color:#e2e8f0;font-size:1rem}
  button{margin-top:20px;width:100%;padding:13px;border:0;border-radius:10px;background:#22c55e;
    color:#052e16;font-weight:700;font-size:1rem;cursor:pointer}
  .msg{line-height:1.5;color:#cbd5e1}
  .err{background:#7f1d1d;color:#fecaca;padding:10px;border-radius:8px;font-size:.85rem;margin-top:12px}
  .sub{color:#94a3b8;font-size:.85rem}
</style></head>
<body><div class="card">$body</div></body></html>''';

/// The checkout form for a resolved payment link.
String _checkoutForm(String code, Map<String, dynamic> link, {String? error}) {
  final title = _esc('${link['title'] ?? 'Make a payment'}');
  final fixed = link['amount'] as num?;
  final allowCustom = link['allowCustomAmount'] == true;
  final amountBlock = allowCustom
      ? '<label for="amount">Amount (KES)</label>'
          '<input id="amount" name="amount" type="number" min="1" inputmode="numeric" '
          '${fixed != null ? 'value="$fixed"' : ''} required>'
      : '<div class="amt">KES ${fixed ?? ''}</div>';
  final errBlock = error == null ? '' : '<div class="err">${_esc(error)}</div>';
  return _page(title, '''
    <h1>$title</h1>
    <p class="sub">Pay securely with M-Pesa.</p>
    $amountBlock
    <form method="POST" action="?c=${_esc(code)}">
      <label for="phone">M-Pesa phone number</label>
      <input id="phone" name="phone" type="tel" placeholder="07XX XXX XXX" required>
      $errBlock
      <button type="submit">Pay now</button>
    </form>''');
}
