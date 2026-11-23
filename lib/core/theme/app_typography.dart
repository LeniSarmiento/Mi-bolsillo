import 'package:material_ui/material_ui.dart';

/// Material 3 typography scale ensuring every visible text is >= 14 px.
abstract final class AppTypography {
  static const String _family = 'Inter';

  static TextTheme buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: _family,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: _family,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: primaryColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: _family,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: primaryColor,
      ),
      titleLarge: TextStyle(
        fontFamily: _family,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontFamily: _family,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: primaryColor,
      ),
      titleSmall: TextStyle(
        fontFamily: _family,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: primaryColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: _family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondaryColor,
      ),
      bodySmall: TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontFamily: _family,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: primaryColor,
      ),
      labelMedium: TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: primaryColor,
      ),
      labelSmall: TextStyle(
        fontFamily: _family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: secondaryColor,
      ),
    );
  }
}
