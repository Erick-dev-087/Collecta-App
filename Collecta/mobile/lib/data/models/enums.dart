/// Domain enums mirroring the backend (`constants/enums.dart`).
library;


enum PaymentStatus {
  initiated,
  pending,
  completed,
  failed,
  cancelled;

  static PaymentStatus fromString(String? s) => switch (s) {
        'initiated' => PaymentStatus.initiated,
        'pending' => PaymentStatus.pending,
        'completed' => PaymentStatus.completed,
        'failed' => PaymentStatus.failed,
        'cancelled' => PaymentStatus.cancelled,
        _ => PaymentStatus.initiated,
      };

  String get wire => name;

  bool get isTerminal =>
      this == PaymentStatus.completed ||
      this == PaymentStatus.failed ||
      this == PaymentStatus.cancelled;
}

enum EventStatus {
  draft,
  active,
  closed,
  cancelled,
  expired;

  static EventStatus fromString(String? s) => switch (s) {
        'active' => EventStatus.active,
        'closed' => EventStatus.closed,
        'cancelled' => EventStatus.cancelled,
        'expired' => EventStatus.expired,
        _ => EventStatus.draft,
      };

  String get wire => name;

  String get label => switch (this) {
        EventStatus.draft => 'Draft',
        EventStatus.active => 'Active',
        EventStatus.closed => 'Closed',
        EventStatus.cancelled => 'Cancelled',
        EventStatus.expired => 'Expired',
      };
}

enum PaymentDestinationType {
  paybill,
  till;

  static PaymentDestinationType fromString(String? s) =>
      s == 'till' ? PaymentDestinationType.till : PaymentDestinationType.paybill;

  String get wire => name;
}

enum UserRole {
  admin,
  manager;

  static UserRole fromString(String? s) =>
      s == 'admin' ? UserRole.admin : UserRole.manager;

  String get wire => name;
}

/// Derived per-member settlement state for a collection — drives the Ledger
/// filters (Full / Partial / Pending).
enum PaidStatus {
  full,
  partial,
  pending;

  String get label => switch (this) {
        PaidStatus.full => 'Paid Full',
        PaidStatus.partial => 'Partial',
        PaidStatus.pending => 'Pending',
      };
}
