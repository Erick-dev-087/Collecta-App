import 'enums.dart';

/// M-Pesa STK destination (paybill/till) for an organization.
class PaymentDestination {
  const PaymentDestination({
    required this.id,
    required this.type,
    required this.shortcode,
    this.accountNumber,
    this.name,
    this.hasPasskey = false,
    this.isActive = true,
    this.isDefault = false,
  });

  final String id;
  final PaymentDestinationType type;
  final String shortcode;
  final String? accountNumber;
  final String? name;
  final bool hasPasskey;
  final bool isActive;
  final bool isDefault;

  factory PaymentDestination.fromMap(Map<String, dynamic> m) =>
      PaymentDestination(
        id: '${m['id']}',
        type: PaymentDestinationType.fromString(m['type'] as String?),
        shortcode: '${m['shortcode'] ?? ''}',
        accountNumber: m['accountNumber'] as String?,
        name: m['name'] as String?,
        hasPasskey: m['hasPasskey'] as bool? ?? false,
        isActive: m['isActive'] as bool? ?? true,
        isDefault: m['isDefault'] as bool? ?? false,
      );
}

/// Organization profile + branding + WhatsApp ledger template settings.
class Organization {
  const Organization({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.classification = 'Faith-Based / Church',
    this.currency = 'KES',
    this.treasuryEmail,
    this.verificationPhone,
    this.logoUrl,
    this.instantStkTrigger = true,
    this.ledgerHeader = '[EVENT NAME] - [ORGANIZATION NAME]',
    this.ledgerFooter = 'Generated via Collecta Reconciliation Engine',
    this.showReceiptIds = true,
    this.includePayLink = true,
    this.destinations = const [],
  });

  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String classification;
  final String currency;
  final String? treasuryEmail;
  final String? verificationPhone;
  final String? logoUrl;
  final bool instantStkTrigger;
  final String ledgerHeader;
  final String ledgerFooter;
  final bool showReceiptIds;
  final bool includePayLink;
  final List<PaymentDestination> destinations;

  PaymentDestination? get defaultDestination {
    for (final d in destinations) {
      if (d.isDefault && d.isActive) return d;
    }
    return destinations.isEmpty ? null : destinations.first;
  }

  factory Organization.fromMap(Map<String, dynamic> m) => Organization(
        id: '${m['id']}',
        name: '${m['name'] ?? ''}',
        slug: m['slug'] as String?,
        description: m['description'] as String?,
        classification: '${m['classification'] ?? 'Faith-Based / Church'}',
        currency: '${m['currency'] ?? 'KES'}',
        treasuryEmail: m['treasuryEmail'] as String?,
        verificationPhone: m['verificationPhone'] as String?,
        logoUrl: m['logoUrl'] as String?,
        instantStkTrigger: m['instantStkTrigger'] as bool? ?? true,
      );

  Organization copyWith({
    String? name,
    String? classification,
    String? currency,
    String? treasuryEmail,
    String? verificationPhone,
    bool? instantStkTrigger,
    String? ledgerHeader,
    String? ledgerFooter,
    bool? showReceiptIds,
    bool? includePayLink,
    List<PaymentDestination>? destinations,
  }) =>
      Organization(
        id: id,
        name: name ?? this.name,
        slug: slug,
        description: description,
        classification: classification ?? this.classification,
        currency: currency ?? this.currency,
        treasuryEmail: treasuryEmail ?? this.treasuryEmail,
        verificationPhone: verificationPhone ?? this.verificationPhone,
        logoUrl: logoUrl,
        instantStkTrigger: instantStkTrigger ?? this.instantStkTrigger,
        ledgerHeader: ledgerHeader ?? this.ledgerHeader,
        ledgerFooter: ledgerFooter ?? this.ledgerFooter,
        showReceiptIds: showReceiptIds ?? this.showReceiptIds,
        includePayLink: includePayLink ?? this.includePayLink,
        destinations: destinations ?? this.destinations,
      );
}

/// The signed-in administrator/treasurer.
class AppUser {
  const AppUser({
    required this.uid,
    required this.orgId,
    required this.fullName,
    required this.email,
    this.role = UserRole.admin,
    this.roleTitle = 'Treasurer',
  });

  final String uid;
  final String orgId;
  final String fullName;
  final String email;
  final UserRole role;
  final String roleTitle;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return fullName.isEmpty ? '?' : fullName.substring(0, 1);
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
