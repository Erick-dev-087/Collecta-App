import 'enums.dart';

/// A collection / cause / event that members contribute toward.
class Collection {
  const Collection({
    required this.id,
    required this.title,
    this.description,
    this.category = 'Trips & Events',
    this.eventDate,
    this.defaultAmount,
    this.targetAmount,
    this.allowCustomAmount = true,
    this.status = EventStatus.active,
    this.imageUrl,
    this.totalCollected = 0,
    this.paymentCount = 0,
    this.contributorCount = 0,
    this.memberTarget,
    this.shortCode,
    this.createdAt,
    this.paymentDestinationType,
    this.paymentShortcode,
    this.paymentAccountNumber,
  });

  final String id;
  final String title;
  final String? description;

  /// UI grouping: Trips & Events, Capital Projects, Youth & Camps, Welfare.
  final String category;
  final DateTime? eventDate;

  /// Expected amount per member (KES, whole).
  final num? defaultAmount;

  /// Overall campaign goal (KES, whole).
  final num? targetAmount;
  final bool allowCustomAmount;
  final EventStatus status;
  final String? imageUrl;
  final num totalCollected;
  final int paymentCount;
  final int contributorCount;

  /// Expected number of contributors (e.g. "/ 50 members").
  final int? memberTarget;

  /// Short code for the sharable payment link.
  final String? shortCode;
  final DateTime? createdAt;

  /// Optional per-collection payment channel override.
  final String? paymentDestinationType;
  final String? paymentShortcode;
  final String? paymentAccountNumber;

  double get progress {
    final t = targetAmount;
    if (t == null || t <= 0) return 0;
    return (totalCollected / t).clamp(0, 1).toDouble();
  }

  String get payLink =>
      'collecta.co/pay/${shortCode ?? id.toLowerCase()}';

  factory Collection.fromMap(Map<String, dynamic> m) => Collection(
        id: '${m['id']}',
        title: '${m['title'] ?? ''}',
        description: m['description'] as String?,
        category: '${m['category'] ?? 'Trips & Events'}',
        eventDate: m['eventDate'] == null
            ? null
            : DateTime.tryParse('${m['eventDate']}'),
        defaultAmount: m['defaultAmount'] as num?,
        targetAmount: m['targetAmount'] as num?,
        allowCustomAmount: m['allowCustomAmount'] as bool? ?? true,
        status: EventStatus.fromString(m['status'] as String?),
        imageUrl: m['imageUrl'] as String?,
        totalCollected: (m['totalCollected'] as num?) ?? 0,
        paymentCount: (m['paymentCount'] as num?)?.toInt() ?? 0,
        contributorCount: (m['contributorCount'] as num?)?.toInt() ?? 0,
        memberTarget: (m['memberTarget'] as num?)?.toInt(),
        shortCode: m['shortCode'] as String?,
        createdAt: m['createdAt'] == null
            ? null
            : DateTime.tryParse('${m['createdAt']}'),
        paymentDestinationType: m['paymentDestinationType'] as String?,
        paymentShortcode: m['paymentShortcode'] as String?,
        paymentAccountNumber: m['paymentAccountNumber'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'eventDate': eventDate?.toIso8601String(),
        'defaultAmount': defaultAmount,
        'targetAmount': targetAmount,
        'allowCustomAmount': allowCustomAmount,
        'status': status.wire,
        'paymentDestinationType': paymentDestinationType,
        'paymentShortcode': paymentShortcode,
        'paymentAccountNumber': paymentAccountNumber,
      };

  Collection copyWith({
    num? totalCollected,
    int? paymentCount,
    int? contributorCount,
    EventStatus? status,
  }) =>
      Collection(
        id: id,
        title: title,
        description: description,
        category: category,
        eventDate: eventDate,
        defaultAmount: defaultAmount,
        targetAmount: targetAmount,
        allowCustomAmount: allowCustomAmount,
        status: status ?? this.status,
        imageUrl: imageUrl,
        totalCollected: totalCollected ?? this.totalCollected,
        paymentCount: paymentCount ?? this.paymentCount,
        contributorCount: contributorCount ?? this.contributorCount,
        memberTarget: memberTarget,
        shortCode: shortCode,
        createdAt: createdAt,
        paymentDestinationType: paymentDestinationType,
        paymentShortcode: paymentShortcode,
        paymentAccountNumber: paymentAccountNumber,
      );
}
