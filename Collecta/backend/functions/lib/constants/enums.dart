/// Shared enums / constants used across models, services and handlers.
library;


class UserRole {
  static const String admin = 'admin';
  static const String manager = 'manager';
  static const List<String> all = [admin, manager];
}

class PaymentStatus {
  static const String initiated = 'initiated';
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
  static const List<String> all = [
    initiated,
    pending,
    completed,
    failed,
    cancelled,
  ];

  /// Statuses that are still awaiting a Daraja callback / query result.
  static const List<String> nonTerminal = [initiated, pending];
}

class PaymentChannel {
  static const String stkPush = 'stk_push';
  static const String cash = 'cash';
}

class EventStatus {
  static const String draft = 'draft';
  static const String active = 'active';
  static const String closed = 'closed';
  static const List<String> all = [draft, active, closed];
}

class PaymentDestinationType {
  static const String paybill = 'paybill';
  static const String till = 'till';
  static const List<String> all = [paybill, till];
}

/// A payment left non-terminal longer than this is considered "stuck" and can
/// be reconciled via an STK status query. Safaricom expires STK prompts well
/// within this window.
const int stuckPaymentMinutes = 5;
