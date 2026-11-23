import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/formatting/date_formatter.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/income/domain/additional_income.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// Screen 5: Registrar ingreso adicional.
/// Success feedback MUST NOT be visible initially; it appears ONLY via snackbar after saving.
class RegisterIncomeScreen extends ConsumerStatefulWidget {
  const RegisterIncomeScreen({super.key, this.existingIncome});

  final AdditionalIncome? existingIncome;

  @override
  ConsumerState<RegisterIncomeScreen> createState() =>
      _RegisterIncomeScreenState();
}

class _RegisterIncomeScreenState extends ConsumerState<RegisterIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  late final TextEditingController _noteController;

  late String _origin;
  late DateTime _date;
  late String _receptionMethod;
  late bool _isRecurring;
  late RecurrenceFrequency _recurrenceFrequency;
  String? _formError;

  bool get _isEditing => widget.existingIncome != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingIncome;
    _amountController = TextEditingController(
      text: existing != null
          ? CopFormatter.formatDigits(existing.amountCop)
          : '',
    );
    _reasonController = TextEditingController(text: existing?.reason ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _origin = existing?.origin ?? IncomeOrigins.all.first;
    _date = existing?.date ?? DateTime.now();
    _receptionMethod =
        existing?.receptionMethod ?? PaymentMethods.incomeChannels.first;
    _isRecurring =
        existing != null && existing.recurrence != RecurrenceFrequency.none;
    _recurrenceFrequency =
        (existing != null && existing.recurrence != RecurrenceFrequency.none)
        ? existing.recurrence
        : RecurrenceFrequency.monthly;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int deltaCop) {
    final current = CopFormatter.parseDigits(_amountController.text) ?? 0;
    final updated = current + deltaCop;
    _amountController.text = CopFormatter.formatDigits(updated);
    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'CO'),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day, 12, 0);
      });
    }
  }

  Future<void> _saveIncome() async {
    final amount = CopFormatter.parseDigits(_amountController.text);
    final reason = _reasonController.text.trim();
    if (!(_formKey.currentState?.validate() ?? false) ||
        amount == null ||
        amount <= 0 ||
        reason.isEmpty) {
      setState(() {
        _formError = 'Ingresa un monto válido en COP y el motivo del ingreso.';
      });
      return;
    }

    setState(() => _formError = null);
    final recurrence = _isRecurring
        ? _recurrenceFrequency
        : RecurrenceFrequency.none;
    final controller = ref.read(incomeControllerProvider.notifier);

    if (_isEditing) {
      await controller.updateIncome(
        widget.existingIncome!.copyWith(
          amountCop: amount,
          reason: reason,
          origin: _origin,
          date: _date,
          receptionMethod: _receptionMethod,
          note: _noteController.text.trim(),
          recurrence: recurrence,
        ),
      );
    } else {
      await controller.addIncome(
        amountCop: amount,
        reason: reason,
        origin: _origin,
        date: _date,
        receptionMethod: _receptionMethod,
        note: _noteController.text.trim(),
        recurrence: recurrence,
      );
    }

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      _isEditing
          ? 'Ingreso adicional actualizado correctamente'
          : 'Ingreso adicional guardado correctamente (+${CopFormatter.format(amount)})',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Editar ingreso adicional'
              : 'Registrar ingreso adicional',
        ),
      ),
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
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CopFormatter.inputFormatter],
                      style: theme.textTheme.headlineMedium,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Monto recibido (COP)',
                        hintText: '350.000',
                        prefixText: '\$ ',
                        suffixText: 'COP',
                      ),
                      validator: (value) {
                        final parsed = CopFormatter.parseDigits(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Ingresa un monto mayor a \$0 COP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ActionChip(
                          label: const Text('+ \$50.000'),
                          onPressed: () => _addQuickAmount(50000),
                        ),
                        ActionChip(
                          label: const Text('+ \$150.000'),
                          onPressed: () => _addQuickAmount(150000),
                        ),
                        ActionChip(
                          label: const Text('+ \$300.000'),
                          onPressed: () => _addQuickAmount(300000),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _reasonController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Motivo del ingreso',
                        hintText: 'Ej. Horas extras fin de semana',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Escribe el motivo del ingreso adicional';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Origen', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: IncomeOrigins.all.map((origin) {
                        return ChoiceChip(
                          label: Text(origin),
                          selected: _origin == origin,
                          onSelected: (_) => setState(() => _origin = origin),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Fecha de recepción',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(DateFormatter.shortDate(_date)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Medio de recepción',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: PaymentMethods.incomeChannels.map((channel) {
                        return ChoiceChip(
                          label: Text(channel),
                          selected: _receptionMethod == channel,
                          onSelected: (_) =>
                              setState(() => _receptionMethod = channel),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        hintText: 'Cliente, proyecto o detalle adicional...',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              value: _isRecurring,
                              onChanged: (val) =>
                                  setState(() => _isRecurring = val),
                              title: const Text('Repetir este ingreso'),
                              subtitle: const Text(
                                'Configura si este ingreso adicional es periódico.',
                              ),
                            ),
                            if (_isRecurring) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: Wrap(
                                  spacing: AppSpacing.xs,
                                  children:
                                      [
                                        RecurrenceFrequency.weekly,
                                        RecurrenceFrequency.biweekly,
                                        RecurrenceFrequency.monthly,
                                      ].map((freq) {
                                        return ChoiceChip(
                                          label: Text(freq.label),
                                          selected:
                                              _recurrenceFrequency == freq,
                                          onSelected: (_) => setState(
                                            () => _recurrenceFrequency = freq,
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ),
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
                          Icon(
                            Icons.info_outline_rounded,
                            color: semantic.income,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Este ingreso se suma a "Ingresos adicionales" sin alterar tu salario base mensual.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: _saveIncome,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar ingreso'),
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
