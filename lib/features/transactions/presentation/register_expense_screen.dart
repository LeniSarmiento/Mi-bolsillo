import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/formatting/date_formatter.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/core/widgets/confirm_delete_dialog.dart';
import 'package:mi_bolsillo/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// Screen 4: Registrar gasto (y edición de movimiento existente).
class RegisterExpenseScreen extends ConsumerStatefulWidget {
  const RegisterExpenseScreen({
    super.key,
    this.existingTransaction,
    this.futureOnly = false,
  });

  final TransactionItem? existingTransaction;
  final bool futureOnly;

  @override
  ConsumerState<RegisterExpenseScreen> createState() =>
      _RegisterExpenseScreenState();
}

class _RegisterExpenseScreenState extends ConsumerState<RegisterExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;

  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  late RecurrenceFrequency _recurrence;
  String? _formError;
  bool _saving = false;

  Future<void> _saveOnce() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _save();
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

  bool get _isEditing => widget.existingTransaction != null;
  bool get _occurrenceOnly =>
      !widget.futureOnly &&
      _isEditing &&
      (widget.existingTransaction!.parentId != null ||
          widget.existingTransaction!.recurrence != RecurrenceFrequency.none);

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    _amountController = TextEditingController(
      text: tx != null ? CopFormatter.formatDigits(tx.amountCop) : '',
    );
    _descriptionController = TextEditingController(text: tx?.description ?? '');
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedCategory = tx?.categoryOrOrigin ?? ExpenseCategory.food.label;
    _selectedPaymentMethod =
        tx?.paymentMethod ?? PaymentMethods.expenseChannels.first;
    _selectedDate = tx?.date ?? DateTime.now();
    _recurrence = _occurrenceOnly
        ? RecurrenceFrequency.none
        : tx?.recurrence ?? RecurrenceFrequency.none;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.futureOnly && _selectedDate.isBefore(tomorrow)
          ? tomorrow
          : _selectedDate,
      firstDate: widget.futureOnly ? tomorrow : DateTime(2023),
      lastDate: DateTime(today.year + 10, 12, 31),
      locale: const Locale('es', 'CO'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final today = DateTime.now();
    if (widget.futureOnly &&
        !_selectedDate.isAfter(
          DateTime(today.year, today.month, today.day, 23, 59, 59, 999),
        )) {
      setState(
        () => _formError = 'Elige una primera repetición posterior a hoy.',
      );
      return;
    }
    final amount = CopFormatter.parseDigits(_amountController.text);
    final description = _descriptionController.text.trim();
    if (!(_formKey.currentState?.validate() ?? false) ||
        amount == null ||
        amount <= 0 ||
        description.isEmpty) {
      setState(() {
        _formError = 'Completa un monto válido en COP y una descripción.';
      });
      return;
    }

    setState(() => _formError = null);
    final controller = ref.read(transactionsControllerProvider.notifier);

    if (_isEditing) {
      await controller.updateTransaction(
        widget.existingTransaction!.copyWith(
          amountCop: amount,
          description: description,
          categoryOrOrigin: _selectedCategory,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          recurrence: _recurrence,
          note: _noteController.text.trim(),
        ),
        futureOnly: widget.futureOnly,
      );
    } else {
      await controller.addExpense(
        amountCop: amount,
        description: description,
        category: _selectedCategory,
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        recurrence: _recurrence,
        note: _noteController.text.trim(),
      );
    }

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      widget.futureOnly
          ? 'Próximas repeticiones actualizadas'
          : _isEditing
          ? 'Movimiento actualizado correctamente'
          : 'Gasto guardado correctamente (${CopFormatter.format(amount)})',
    );
    context.pop();
  }

  Future<void> _stopFuture() async {
    if (_saving) return;
    final accepted = await ConfirmDeleteDialog.show(
      context,
      title: '¿Detener próximas repeticiones?',
      description: 'Se cancelarán los próximos movimientos de esta serie. El historial anterior se conserva.',
      confirmLabel: 'Detener',
    );
    if (!accepted || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(transactionsControllerProvider.notifier)
          .stopFuture(widget.existingTransaction!.id);
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Próximas repeticiones detenidas');
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _formError =
              'No se pudo detener la programación. Recarga los movimientos.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(dashboardSummaryProvider);
    final isBusy =
        _saving ||
        ref.watch(transactionsControllerProvider.select((s) => s.isSaving));
    final enteredAmount = CopFormatter.parseDigits(_amountController.text) ?? 0;
    final projectedAvailable = previewExpenseBalance(
      availableCop: summary.availableCop,
      amountCop: enteredAmount,
      date: _selectedDate,
      today: DateTime.now(),
      original: widget.existingTransaction,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.futureOnly
              ? 'Próximos gastos'
              : _isEditing
              ? 'Editar gasto'
              : 'Registrar gasto',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    if (widget.futureOnly)
                      const Text(
                        'Los cambios empiezan en la primera fecha indicada. Los gastos anteriores no cambian.',
                      ),
                    if (!_isEditing) ...[
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.arrow_downward_rounded),
                            label: Text(
                              'Registrar gasto',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.arrow_upward_rounded),
                            label: Text(
                              'Ingreso adicional',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        selected: const {true},
                        onSelectionChanged: isBusy
                            ? null
                            : (selection) {
                                if (!selection.first) {
                                  context.pushReplacement(
                                    AppRoutes.registerIncome,
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (_formError != null) ...[
                      FormErrorBanner(message: _formError!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _amountController,
                      enabled: !isBusy,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      inputFormatters: [CopFormatter.inputFormatter],
                      style: theme.textTheme.headlineMedium,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Monto del gasto (COP)',
                        hintText: '45.000',
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
                    Text(
                      widget.futureOnly
                          ? 'Esta programación no cambia el disponible de hoy.'
                          : 'Disponible estimado después del gasto: ${CopFormatter.format(projectedAvailable)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: projectedAvailable < 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isBusy,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej. Almuerzo ejecutivo',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Describe en qué realizaste el gasto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Categoría', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: ExpenseCategory.values.map((cat) {
                        final selected = _selectedCategory == cat.label;
                        return ChoiceChip(
                          avatar: Icon(cat.icon, size: 18),
                          label: Text(cat.label),
                          selected: selected,
                          onSelected: isBusy
                              ? null
                              : (_) => setState(
                                  () => _selectedCategory = cat.label,
                                ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.futureOnly ? 'Primera repetición' : 'Fecha',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(DateFormatter.shortDate(_selectedDate)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Medio de pago', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: PaymentMethods.expenseChannels.map((channel) {
                        return ChoiceChip(
                          label: Text(channel),
                          selected: _selectedPaymentMethod == channel,
                          onSelected: isBusy
                              ? null
                              : (_) => setState(
                                  () => _selectedPaymentMethod = channel,
                                ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Recurrencia', style: theme.textTheme.titleMedium),
                    if (_occurrenceOnly)
                      const Text(
                        'Editas solo este movimiento. Para cambiar la serie, elige Próximas repeticiones desde Movimientos.',
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: RecurrenceFrequency.values
                          .where(
                            (freq) =>
                                !widget.futureOnly ||
                                freq != RecurrenceFrequency.none,
                          )
                          .map((freq) {
                            return ChoiceChip(
                              label: Text(freq.label),
                              selected: _recurrence == freq,
                              onSelected: isBusy || _occurrenceOnly
                                  ? null
                                  : (_) => setState(() => _recurrence = freq),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _noteController,
                      enabled: !isBusy,
                      maxLines: 2,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      decoration: const InputDecoration(
                        labelText: 'Nota opcional',
                        hintText: 'Detalles adicionales...',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: isBusy ? null : _saveOnce,
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        isBusy
                            ? 'Guardando...'
                            : widget.futureOnly
                            ? 'Guardar próximas repeticiones'
                            : _isEditing
                            ? 'Actualizar gasto'
                            : 'Guardar gasto',
                      ),
                    ),
                    if (widget.futureOnly)
                      TextButton(
                        onPressed: isBusy ? null : _stopFuture,
                        child: const Text('Detener próximas repeticiones'),
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
