import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/formatting/date_formatter.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// Screen 4: Registrar gasto (y edición de movimiento existente).
class RegisterExpenseScreen extends ConsumerStatefulWidget {
  const RegisterExpenseScreen({super.key, this.existingTransaction});

  final TransactionItem? existingTransaction;

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
    _recurrence = tx?.recurrence ?? RecurrenceFrequency.none;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
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
      _isEditing
          ? 'Movimiento actualizado correctamente'
          : 'Gasto guardado correctamente (${CopFormatter.format(amount)})',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(dashboardSummaryProvider);
    final enteredAmount = CopFormatter.parseDigits(_amountController.text) ?? 0;
    final projectedAvailable = _isEditing
        ? summary.availableCop +
              widget.existingTransaction!.amountCop -
              enteredAmount
        : summary.availableCop - enteredAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar gasto' : 'Registrar gasto'),
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
                    if (!_isEditing) ...[
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.arrow_downward_rounded),
                            label: Text('Registrar gasto'),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.arrow_upward_rounded),
                            label: Text('Ingreso adicional'),
                          ),
                        ],
                        selected: const {true},
                        onSelectionChanged: (selection) {
                          if (!selection.first) {
                            context.pushReplacement(AppRoutes.registerIncome);
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
                      keyboardType: TextInputType.number,
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
                      'Disponible estimado después del gasto: ${CopFormatter.format(projectedAvailable)}',
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
                      textCapitalization: TextCapitalization.sentences,
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
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat.label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Fecha', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
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
                          onSelected: (_) =>
                              setState(() => _selectedPaymentMethod = channel),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Recurrencia', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: RecurrenceFrequency.values.map((freq) {
                        return ChoiceChip(
                          label: Text(freq.label),
                          selected: _recurrence == freq,
                          onSelected: (_) => setState(() => _recurrence = freq),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Nota opcional',
                        hintText: 'Detalles adicionales...',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveOnce,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        _isEditing ? 'Actualizar gasto' : 'Guardar gasto',
                      ),
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
