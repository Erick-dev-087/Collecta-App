import 'package:intl/intl.dart';

final _kes = NumberFormat.decimalPattern('en');

/// "KES 72,000"
String kes(num? v) => 'KES ${_kes.format((v ?? 0).round())}';

/// "72,000" (no currency prefix)
String kesPlain(num? v) => _kes.format((v ?? 0).round());

/// "1.2M" / "84K" compact for tight metric chips.
String kesCompact(num? v) {
  final n = (v ?? 0).toDouble();
  if (n >= 1000000) return 'KES ${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
  if (n >= 1000) return 'KES ${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  return kes(n);
}

String dateMedium(DateTime? d) =>
    d == null ? '—' : DateFormat('d MMM yyyy').format(d);

String dateShort(DateTime? d) =>
    d == null ? '—' : DateFormat('d MMM').format(d);

String timestampAudit(DateTime? d) =>
    d == null ? '—' : DateFormat('d MMM, h:mm a').format(d);

String pct(double fraction) => '${(fraction * 100).round()}%';
