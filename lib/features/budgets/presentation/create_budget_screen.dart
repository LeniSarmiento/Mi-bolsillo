import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/budgets/application/budgets_controller.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// Screen 11: Crear presupuesto con ritmo diario y alertas preventivas al 80%/100%.
class CreateBudgetScreen extends ConsumerStatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _limitController = TextEditingController(
    text: '600.000',
  );

  String _selectedCategory = ExpenseCategory.food.label;
  BudgetPeriod _period = BudgetPeriod.monthly;
  bool _alert80 = true;
  bool _alert100 = true;
  String? _formError;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _addQuick(int deltaCop) {
    final current = CopFormatter.parseDigits(_limitController.text) ?? 0;
    _limitController.text = CopFormatter.formatDigits(current + deltaCop);
    setState(() {});
  }

  Future<void> _saveBudget() async {
    final limit = CopFormatter.parseDigits(_limitController.text);
    if (!(_formKey.currentState?.validate() ?? false) ||
        limit == null ||
        limit <= 0) {
      setState(() {
        _formError = 'Ingresa un límite válido en pesos colombianos.';
      });
      return;
    }

    setState(() => _formError = null);
    await ref
        .read(budgetsControllerProvider.notifier)
        .saveBudget(
          category: _selectedCategory,
          limitCop: limit,
          period: _period,
          alertAt80: _alert80,
          alertAt100: _alert100,
        );

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      'Presupuesto de $_selectedCategory guardado (${CopFormatter.format(limit)})',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final limit = CopFormatter.parseDigits(_limitController.text) ?? 0;
    final dailyLimit = limit > 0 ? limit ~/ _period.days : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear presupuesto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.pagePadding(context)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth(context),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_formError != null) ...[
                      FormErrorBanner(message: _formError!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      'Categoría de gasto',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: ExpenseCategory.values.map((cat) {
                        return ChoiceChip(
                          avatar: Icon(cat.icon, size: 18),
                          label: Text(cat.label),
                          selected: _selectedCategory == cat.label,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat.label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Período del presupuesto',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: BudgetPeriod.values.map((period) {
                        return ChoiceChip(
                          label: Text(period.label),
                          selected: _period == period,
                          onSelected: (_) => setState(() => _period = period),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CopFormatter.inputFormatter],
                      style: theme.textTheme.headlineMedium,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Límite máximo (COP)',
                        prefixText: '\$ ',
                        suffixText: 'COP',
                      ),
                      validator: (value) {
                        final parsed = CopFormatter.parseDigits(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Ingresa un límite mayor a \$0 COP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        ActionChip(
                          label: const Text('+ \$200.000'),
                          onPressed: () => _addQuick(200000),
                        ),
                        ActionChip(
                          label: const Text('+ \$500.000'),
                          onPressed: () => _addQuick(500000),
                        ),
                        ActionChip(
                          label: const Text('+ \$1.000.000'),
                          onPressed: () => _addQuick(1000000),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: semantic.incomeContainer,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.speed_rounded, color: semantic.income),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Tu límite diario será ~${CopFormatter.format(dailyLimit)} / día (${_period.days} días).',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: semantic.income,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Alertas preventivas inteligentes',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Card(
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _alert80,
                            onChanged: (v) =>
                                setState(() => _alert80 = v ?? true),
                            title: const Text('Avisarme al llegar al 80 %'),
                            subtitle: const Text(
                              'Alerta preventiva naranja antes de agotar el tope.',
                            ),
                          ),
                          const Divider(height: 1),
                          CheckboxListTile(
                            value: _alert100,
                            onChanged: (v) =>
                                setState(() => _alert100 = v ?? true),
                            title: const Text('Avisarme al llegar al 100 %'),
                            subtitle: const Text(
                              'Notifica cuando el presupuesto esté agotado.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: _saveBudget,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar presupuesto'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
