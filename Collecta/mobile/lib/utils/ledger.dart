import '../data/models/analytics.dart';
import '../data/models/collection.dart';
import '../data/models/enums.dart';
import '../data/models/member.dart';
import '../data/models/organization.dart';
import '../data/models/payment.dart';
import 'formatters.dart';

/// Build the reconciled contributor rows for a collection from the raw member
/// directory + payment history. Drives the Ledger filters (Full/Partial/Pending).
List<LedgerEntry> buildLedger(
  Collection collection,
  List<Member> members,
  List<Payment> payments,
) {
  final expected = (collection.defaultAmount ?? 0);
  final byId = {for (final m in members) m.id: m};
  final grouped = <String, List<Payment>>{};
  for (final p in payments.where((p) => p.eventId == collection.id)) {
    final key = p.memberId ?? p.phone;
    grouped.putIfAbsent(key, () => []).add(p);
  }

  final entries = <LedgerEntry>[];
  grouped.forEach((key, ps) {
    final member = byId[key] ??
        Member(
          id: key,
          fullName: ps.first.payerName ?? key,
          phone: ps.first.phone,
          autoCreated: true,
        );
    final completed =
        ps.where((p) => p.status == PaymentStatus.completed).toList();
    final paid = completed.fold<num>(0, (s, p) => s + p.amount);
    final PaidStatus status;
    if (expected > 0 && paid >= expected) {
      status = PaidStatus.full;
    } else if (paid > 0) {
      status = PaidStatus.partial;
    } else {
      status = PaidStatus.pending;
    }
    completed.sort((a, b) =>
        (b.completedAt ?? b.initiatedAt).compareTo(a.completedAt ?? a.initiatedAt));
    entries.add(LedgerEntry(
      member: member,
      paid: paid,
      expected: expected,
      status: status,
      receipt: completed.isNotEmpty ? completed.first.mpesaReceiptNumber : null,
      lastPaidAt: completed.isNotEmpty ? completed.first.completedAt : null,
    ));
  });

  const order = {PaidStatus.full: 0, PaidStatus.partial: 1, PaidStatus.pending: 2};
  entries.sort((a, b) {
    final c = order[a.status]!.compareTo(order[b.status]!);
    return c != 0 ? c : a.member.fullName.compareTo(b.member.fullName);
  });
  return entries;
}

/// Compose the WhatsApp-ready, audit-formatted broadcast text (matches the
/// ledger design), honouring the org's template toggles.
String buildWhatsAppPayload(
  Organization org,
  Collection collection,
  List<LedgerEntry> entries,
) {
  final paid = entries.where((e) => e.status != PaidStatus.pending).toList();
  final pending = entries.where((e) => e.status == PaidStatus.pending).toList();
  final totalCollected = paid.fold<num>(0, (s, e) => s + e.paid);

  final header = org.ledgerHeader
      .replaceAll('[EVENT NAME]', collection.title)
      .replaceAll('[ORGANIZATION NAME]', org.name)
      .replaceAll('[DATE]', dateMedium(collection.eventDate))
      .toUpperCase();
  const rule = '======================================';

  final b = StringBuffer()
    ..writeln(header)
    ..writeln(rule)
    ..writeln('Date: ${dateMedium(collection.eventDate)}')
    ..writeln('Target per Member: ${kes(collection.defaultAmount)}')
    ..writeln(
        'Total Collected: ${kes(totalCollected)} (${paid.length} / ${collection.memberTarget ?? paid.length} confirmed)');
  if (org.includePayLink) {
    b.writeln('Payment Link: https://${collection.payLink}');
  }
  b
    ..writeln()
    ..writeln('Payments are verified instantly via M-Pesa STK push.')
    ..writeln()
    ..writeln('List of Attending Members (Paid):');

  for (var i = 0; i < paid.length; i++) {
    final e = paid[i];
    final n = '${i + 1}.'.padRight(4);
    final name = e.member.fullName.padRight(18);
    final amt = kes(e.paid);
    final rec = org.showReceiptIds && e.receipt != null ? '  [${e.receipt}]' : '';
    final partial = e.status == PaidStatus.partial ? '  (partial)' : '';
    b.writeln(' $n$name- $amt$rec$partial');
  }

  if (pending.isNotEmpty) {
    b
      ..writeln()
      ..writeln('Pending Payment (STK Push reminders active):');
    for (final e in pending) {
      b.writeln(' - ${e.member.fullName} (${_maskPhone(e.member.phone)})');
    }
  }

  b
    ..writeln(rule)
    ..write(org.ledgerFooter);
  return b.toString();
}

String _maskPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length < 6) return phone;
  final local = d.length >= 9 ? d.substring(d.length - 9) : d;
  return '0${local.substring(0, 3)}***${local.substring(local.length - 3)}';
}
