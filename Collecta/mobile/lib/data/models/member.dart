/// A contributor in an organization's directory.
class Member {
  const Member({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.gender,
    this.group,
    this.totalContributed = 0,
    this.contributionCount = 0,
    this.lastContributionAt,
    this.stkVerified = true,
    this.carrier = 'STK',
    this.autoCreated = false,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? gender;

  /// Fellowship / group label (e.g. Choir, Youth Guild).
  final String? group;
  final num totalContributed;
  final int contributionCount;
  final DateTime? lastContributionAt;

  /// Whether the number is confirmed Safaricom (M-Pesa STK ready).
  final bool stkVerified;

  /// "STK" (Safaricom) or "Airtel" — carrier chip in the directory.
  final String carrier;
  final bool autoCreated;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  factory Member.fromMap(Map<String, dynamic> m) => Member(
        id: '${m['id']}',
        fullName: '${m['fullName'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        email: m['email'] as String?,
        gender: m['gender'] as String?,
        group: m['group'] as String?,
        totalContributed: (m['totalContributed'] as num?) ?? 0,
        contributionCount: (m['contributionCount'] as num?)?.toInt() ?? 0,
        lastContributionAt: m['lastContributionAt'] == null
            ? null
            : DateTime.tryParse('${m['lastContributionAt']}'),
        stkVerified: m['stkVerified'] as bool? ?? true,
        carrier: '${m['carrier'] ?? 'STK'}',
        autoCreated: m['autoCreated'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'gender': gender,
        'group': group,
      };
}
