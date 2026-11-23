import 'package:material_ui/material_ui.dart';

/// Shared spacing, radius, and adaptive sizing tokens (base 360 x 800 px).
abstract final class AppSpacing {
  static const double baseWidth = 360;
  static const double baseHeight = 800;

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  /// Minimum interactive hit target per Android accessibility guidelines.
  static const double minTouchTarget = 48;

  /// Horizontal padding adapted smoothly across Android phone widths.
  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 600) return 28;
    if (width >= 400) return 20;
    return 16;
  }

  /// Constrains content width cleanly on tablets while filling 360px+ phones.
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > 560 ? 520 : width;
  }
}
