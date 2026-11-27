/// Optional repository operations for changes that must preserve past entries.
abstract interface class RecurrenceRepository<T> {
  Future<T> reviseFuture(T firstOccurrence);
  Future<void> stopFuture(String templateId);
}

/// Route payload: [item.date] is the first future occurrence, never history.
class FutureSeriesEdit<T> {
  const FutureSeriesEdit(this.item);
  final T item;
}
