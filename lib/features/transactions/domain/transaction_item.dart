import 'package:material_ui/material_ui.dart';

enum MovementStatus { pending, confirmed, discarded }

enum MovementSource { manual, notification, recurring }

enum TransactionType { expense, baseIncome, additionalIncome }

enum RecurrenceFrequency {
  none('Sin repetición'),
  weekly('Semanal'),
  biweekly('Quincenal'),
  monthly('Mensual');

  const RecurrenceFrequency(this.label);
  final String label;
}

enum ExpenseCategory {
  food('Alimentación', Icons.restaurant_rounded),
  transport('Transporte', Icons.directions_bus_rounded),
  home('Hogar', Icons.home_rounded),
  health('Salud', Icons.medical_services_rounded),
  leisure('Ocio', Icons.movie_rounded),
  education('Educación', Icons.school_rounded),
  shopping('Compras', Icons.shopping_bag_rounded),
  other('Otros', Icons.category_rounded);

  const ExpenseCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

abstract final class PaymentMethods {
  static const List<String> expenseChannels = [
    'Efectivo',
    'Tarjeta Bancaria',
    'Nequi / Daviplata',
    'Transferencia',
  ];

  static const List<String> incomeChannels = [
    'Efectivo',
    'Transferencia',
    'Nequi',
    'Daviplata',
    'Otro medio',
  ];
}

/// Visual/domain model for a financial movement. All COP amounts are integer pesos.
@immutable
class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.description,
    required this.amountCop,
    required this.type,
    required this.categoryOrOrigin,
    required this.date,
    required this.paymentMethod,
    required this.isAutomatic,
    required this.recurrence,
    this.note = '',
    this.linkedIncomeId,
    this.createdAt,
    this.updatedAt,
    this.status = MovementStatus.confirmed,
    this.source = MovementSource.manual,
    this.parentId,
    this.nextOccurrence,
  });

  final String id;
  final String description;
  final int amountCop;
  final TransactionType type;
  final String categoryOrOrigin;
  final DateTime date;
  final String paymentMethod;
  final bool isAutomatic;
  final RecurrenceFrequency recurrence;
  final String note;
  final String? linkedIncomeId;
  final DateTime? createdAt, updatedAt;
  final MovementStatus status;
  final MovementSource source;
  final String? parentId;
  final DateTime? nextOccurrence;

  bool get isIncome => type != TransactionType.expense;

  TransactionItem copyWith({
    String? id,
    String? description,
    int? amountCop,
    TransactionType? type,
    String? categoryOrOrigin,
    DateTime? date,
    String? paymentMethod,
    bool? isAutomatic,
    RecurrenceFrequency? recurrence,
    String? note,
    String? linkedIncomeId,
  }) {
    return TransactionItem(
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      source: source,
      parentId: parentId,
      nextOccurrence: nextOccurrence,
      id: id ?? this.id,
      description: description ?? this.description,
      amountCop: amountCop ?? this.amountCop,
      type: type ?? this.type,
      categoryOrOrigin: categoryOrOrigin ?? this.categoryOrOrigin,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      recurrence: recurrence ?? this.recurrence,
      note: note ?? this.note,
      linkedIncomeId: linkedIncomeId ?? this.linkedIncomeId,
    );
  }
}
