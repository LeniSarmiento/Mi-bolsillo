import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

abstract final class IncomeOrigins {
  static const List<String> all = [
    'Horas extras',
    'Independiente',
    'Venta',
    'Comisión',
    'Regalo',
    'Devolución',
    'Otro origen',
  ];
}

/// Visual/domain model for confirmed additional income entries (COP integer).
@immutable
class AdditionalIncome {
  const AdditionalIncome({
    required this.id,
    required this.amountCop,
    required this.reason,
    required this.origin,
    required this.date,
    required this.receptionMethod,
    required this.note,
    required this.recurrence,
    this.nextOccurrence,
  });

  final String id;
  final int amountCop;
  final String reason;
  final String origin;
  final DateTime date;
  final String receptionMethod;
  final String note;
  final RecurrenceFrequency recurrence;
  final DateTime? nextOccurrence;

  AdditionalIncome copyWith({
    String? id,
    int? amountCop,
    String? reason,
    String? origin,
    DateTime? date,
    String? receptionMethod,
    String? note,
    RecurrenceFrequency? recurrence,
  }) {
    return AdditionalIncome(
      id: id ?? this.id,
      amountCop: amountCop ?? this.amountCop,
      reason: reason ?? this.reason,
      origin: origin ?? this.origin,
      date: date ?? this.date,
      receptionMethod: receptionMethod ?? this.receptionMethod,
      note: note ?? this.note,
      recurrence: recurrence ?? this.recurrence,
      nextOccurrence: nextOccurrence,
    );
  }
}
