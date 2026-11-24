import 'package:material_ui/material_ui.dart';

/// Emerald Warmth design system colors for Mi Bolsillo.
abstract final class AppColors {
  static const Color primary = Color(0xFF0F5132);
  static const Color primaryContainer = Color(0xFFD1FAE5);
  static const Color primaryDarkSurface = Color(0xFF0B3B24);

  static const Color secondary = Color(0xFF10B981);
  static const Color secondarySoft = Color(0xFF8CD6C0);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainerLight = Color(0xFFFEF3C7);
  static const Color warningContainerDark = Color(0xFF422B08);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEFF1F3);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF191C1E);
  static const Color lightTextSecondary = Color(0xFF4B5563);

  static const Color darkBackground = Color(0xFF0B1210);
  static const Color darkSurface = Color(0xFF13201B);
  static const Color darkSurfaceVariant = Color(0xFF1B2D26);
  static const Color darkBorder = Color(0xFF263B32);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Color expenseLight = Color(0xFFB91C1C);
  static const Color expenseContainerLight = Color(0xFFFEE2E2);
  static const Color expenseDark = Color(0xFFF87171);
  static const Color expenseContainerDark = Color(0xFF451A1A);

  static const Color incomeLight = Color(0xFF0F5132);
  static const Color incomeContainerLight = Color(0xFFD1FAE5);
  static const Color incomeDark = Color(0xFF34D399);
  static const Color incomeContainerDark = Color(0xFF0B3B24);
}

/// Semantic theme extension so widgets never hardcode theme-specific colors.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.income,
    required this.incomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.warning,
    required this.warningContainer,
    required this.heroStart,
    required this.heroEnd,
    required this.cardBorder,
    required this.mutedText,
  });

  final Color income;
  final Color incomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color warning;
  final Color warningContainer;
  final Color heroStart;
  final Color heroEnd;
  final Color cardBorder;
  final Color mutedText;

  static const light = AppSemanticColors(
    income: AppColors.incomeLight,
    incomeContainer: AppColors.incomeContainerLight,
    expense: AppColors.expenseLight,
    expenseContainer: AppColors.expenseContainerLight,
    warning: Color(0xFFB45309),
    warningContainer: AppColors.warningContainerLight,
    heroStart: AppColors.primary,
    heroEnd: Color(0xFF146C43),
    cardBorder: AppColors.lightBorder,
    mutedText: AppColors.lightTextSecondary,
  );

  static const dark = AppSemanticColors(
    income: AppColors.incomeDark,
    incomeContainer: AppColors.incomeContainerDark,
    expense: AppColors.expenseDark,
    expenseContainer: AppColors.expenseContainerDark,
    warning: Color(0xFFFBBF24),
    warningContainer: AppColors.warningContainerDark,
    heroStart: Color(0xFF0B3B24),
    heroEnd: Color(0xFF0F5132),
    cardBorder: AppColors.darkBorder,
    mutedText: AppColors.darkTextSecondary,
  );

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? incomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? warning,
    Color? warningContainer,
    Color? heroStart,
    Color? heroEnd,
    Color? cardBorder,
    Color? mutedText,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      cardBorder: cardBorder ?? this.cardBorder,
      mutedText: mutedText ?? this.mutedText,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer: Color.lerp(
        expenseContainer,
        other.expenseContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}

extension AppSemanticContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
