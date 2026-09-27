/// 8-point baseline grid spacing + corner radii from the design system.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Mobile screen edge margin.
  static const double screenMargin = 16;
  static const double gutter = 12;
}

/// Corner radii (roundedness 2 — medium).
class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double base = 8; // inputs, buttons
  static const double md = 12;
  static const double lg = 16; // cards, dialogs
  static const double xl = 24;
  static const double full = 9999;
}
