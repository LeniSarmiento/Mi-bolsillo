enum FinanceFailureKind { validation, persistence, permission, unavailable }

class FinanceFailure implements Exception {
  const FinanceFailure(this.kind, this.message, [this.cause]);

  final FinanceFailureKind kind;
  final String message;
  final Object? cause;

  static FinanceFailure from(Object error) {
    if (error is FinanceFailure) return error;
    if (error is FormatException || error is ArgumentError) {
      return FinanceFailure(
        FinanceFailureKind.validation,
        'Revisa los datos ingresados e inténtalo nuevamente.',
        error,
      );
    }
    if (error is StateError) {
      return FinanceFailure(
        FinanceFailureKind.unavailable,
        'La operación no está disponible en este momento.',
        error,
      );
    }
    return FinanceFailure(
      FinanceFailureKind.persistence,
      'No se pudieron guardar los cambios en este dispositivo.',
      error,
    );
  }

  @override
  String toString() => message;
}
