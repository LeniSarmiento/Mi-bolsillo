import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';

/// Displays COP monetary values with double-coded icon + sign + semantic color.
class MoneyAmountText extends StatelessWidget {
  const MoneyAmountText({
    super.key,
    required this.amountCop,
    required this.isIncome,
    this.showCurrency = true,
    this.showIcon = true,
    this.style,
  });

  final int amountCop;
  final bool isIncome;
  final bool showCurrency;
  final bool showIcon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final color = isIncome ? semantic.income : semantic.expense;
    final icon = isIncome
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final formatted = CopFormatter.formatSigned(
      amountCop,
      isPositive: isIncome,
      includeCurrency: showCurrency,
    );

    final effectiveStyle = (style ?? Theme.of(context).textTheme.titleSmall)!
        .copyWith(color: color, fontWeight: FontWeight.w700);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(formatted, style: effectiveStyle),
        ],
      ),
    );
  }
}
