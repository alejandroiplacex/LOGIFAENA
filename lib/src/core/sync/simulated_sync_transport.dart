import 'pending_sync_operation.dart';
import 'sync_transport.dart';

typedef SyncFailurePredicate = bool Function(PendingSyncOperation operation);

class SimulatedSyncTransport implements SyncTransport {
  const SimulatedSyncTransport({
    this.delay = const Duration(milliseconds: 250),
    this.failurePredicate,
  });

  final Duration delay;
  final SyncFailurePredicate? failurePredicate;

  @override
  Future<void> send(PendingSyncOperation operation) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (failurePredicate?.call(operation) ?? false) {
      throw StateError(
        'La operación ${operation.id ?? 'sin id'} fue rechazada por el simulador.',
      );
    }
  }
}
