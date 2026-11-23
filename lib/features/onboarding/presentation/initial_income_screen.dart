import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';

/// Screen 2: Configuración inicial del ingreso mensual.
class InitialIncomeScreen extends ConsumerStatefulWidget {
  const InitialIncomeScreen({super.key});

  @override
  ConsumerState<InitialIncomeScreen> createState() =>
      _InitialIncomeScreenState();
}

class _InitialIncomeScreenState extends ConsumerState<InitialIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  PayFrequency _payFrequency = PayFrequency.biweekly;
  bool _autoRepeat = true;
  String? _formError;
  bool _saving = false;
  Future<void> _saveOnce() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _submit();
    } catch (_) {
      if (mounted) {
        setState(
          () => _formError =
              'No se pudo guardar. Revisa los datos e inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = ref.read(settingsControllerProvider);
    _amountController = TextEditingController(
      text: CopFormatter.formatDigits(initial.monthlyIncomeCop),
    );
    _payFrequency = initial.payFrequency;
    _autoRepeat = initial.autoRepeatBaseIncome;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? get _parsedAmount => CopFormatter.parseDigits(_amountController.text);

  Future<void> _submit() async {
    final amount = _parsedAmount;
    if (!(_formKey.currentState?.validate() ?? false) ||
        amount == null ||
        amount <= 0) {
      setState(() {
        _formError = 'Ingresa un ingreso mensual válido en pesos colombianos.';
      });
      return;
    }

    setState(() => _formError = null);
    await ref
        .read(settingsControllerProvider.notifier)
        .completeOnboarding(
          monthlyIncomeCop: amount,
          payFrequency: _payFrequency,
          autoRepeatBaseIncome: _autoRepeat,
        );

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      'Ingreso mensual guardado: ${CopFormatter.format(amount)}',
    );
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final amount = _parsedAmount ?? 0;
    final dailyEstimate = amount > 0 ? amount ~/ 30 : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración Inicial')),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Paso 1 de 2: Tu ingreso base',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Text('50%', style: theme.textTheme.labelMedium),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                      child: const LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '¿Cuánto dinero recibes normalmente al mes?',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Toca el campo para escribir con el teclado numérico de tu teléfono.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      FormErrorBanner(message: _formError!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CopFormatter.inputFormatter],
                      style: theme.textTheme.headlineMedium,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Ingreso mensual base (COP)',
                        prefixText: '\$ ',
                        suffixText: 'COP',
                        suffixIcon: IconButton(
                          tooltip: 'Limpiar monto',
                          onPressed: () {
                            _amountController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      validator: (value) {
                        final parsed = CopFormatter.parseDigits(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Ingresa un monto mayor a \$0 COP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                          Icon(Icons.insights_rounded, color: semantic.income),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Ritmo estimado disponible: ~${CopFormatter.format(dailyEstimate)} / día',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: semantic.income,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '¿Cuándo recibes este dinero?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: PayFrequency.values.map((freq) {
                        final selected = _payFrequency == freq;
                        return ChoiceChip(
                          label: Text(freq.label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _payFrequency = freq);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: SwitchListTile(
                        value: _autoRepeat,
                        onChanged: (val) => setState(() => _autoRepeat = val),
                        title: const Text('Repetir automáticamente'),
                        subtitle: const Text(
                          'Renueva tu ingreso base cada mes sin volver a digitarlo.',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveOnce,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Crear mi presupuesto'),
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
