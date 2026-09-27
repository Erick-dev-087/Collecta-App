import 'enums.dart';

/// A single contribution transaction toward a collection.
class Payment {
  const Payment({
    required this.id,
    required this.orgId,
    required this.eventId,
    this.memberId,
    this.payerName,
    required this.phone,
    required this.amount,
    this.status = PaymentStatus.initiated,
    this.mpesaReceiptNumber,
    this.checkoutRequestId,
    this.paymentLinkId,
    required this.initiatedAt,
    this.completedAt,
  });

  final String id;
  final String orgId;
  final String eventId;
  final String? memberId;
  final String? payerName;
  final String phone;
  final num amount;
  final PaymentStatus status;
  final String? mpesaReceiptNumber;
  final String? checkoutRequestId;
  final String? paymentLinkId;
  final DateTime initiatedAt;
  final DateTime? completedAt;

  /// Masked phone for public/audit display: +254 712 ••• 345.
  String get maskedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return phone;
    final cc = digits.startsWith('254') ? digits : '254${digits.substring(digits.length - 9)}';
    final local = cc.substring(3); // 9 digits
    return '+254 ${local.substring(0, 3)} ••• ${local.substring(local.length - 3)}';
  }

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: '${m['id']}',
        orgId: '${m['orgId'] ?? ''}',
        eventId: '${m['eventId'] ?? ''}',
        memberId: m['memberId'] as String?,
        payerName: m['payerName'] as String?,
        phone: '${m['phone'] ?? ''}',
        amount: (m['amount'] as num?) ?? 0,
        status: PaymentStatus.fromString(m['status'] as String?),
        mpesaReceiptNumber: m['mpesaReceiptNumber'] as String?,
        checkoutRequestId: m['checkoutRequestId'] as String?,
        paymentLinkId: m['paymentLinkId'] as String?,
        initiatedAt:
            DateTime.tryParse('${m['initiatedAt']}') ?? DateTime.now(),
        completedAt: m['completedAt'] == null
            ? null
            : DateTime.tryParse('${m['completedAt']}'),
      );

  Payment copyWith({
    PaymentStatus? status,
    String? mpesaReceiptNumber,
    DateTime? completedAt,
  }) =>
      Payment(
        id: id,
        orgId: orgId,
        eventId: eventId,
        memberId: memberId,
        payerName: payerName,
        phone: phone,
        amount: amount,
        status: status ?? this.status,
        mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
        checkoutRequestId: checkoutRequestId,
        paymentLinkId: paymentLinkId,
        initiatedAt: initiatedAt,
        completedAt: completedAt ?? this.completedAt,
      );
}
