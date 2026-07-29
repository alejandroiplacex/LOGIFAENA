import 'package:flutter_test/flutter_test.dart';
import 'package:logifaena_master/src/core/sync/pending_sync_operation.dart';
import 'package:logifaena_master/src/core/sync/simulated_sync_transport.dart';
import 'package:logifaena_master/src/core/sync/sync_engine.dart';

void main() {
  PendingSyncOperation operation(int id) {
    return PendingSyncOperation(
      id: id,
      entityType: 'worker',
      entityId: 'worker-$id',
      operation: 'update',
      payload: <String, dynamic>{'id': id},
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('completa todas las operaciones enviadas correctamente', () async {
    final sending = <int>[];
    final completed = <int>[];
    final failed = <int>[];

    final engine = SyncEngine(
      transport: const SimulatedSyncTransport(delay: Duration.zero),
      loadPending: () => [operation(1), operation(2)],
      markAsSending: (id) async => sending.add(id),
      markAsCompleted: (id) async => completed.add(id),
      markAsFailed: (id) async => failed.add(id),
    );

    final result = await engine.synchronizePending();

    expect(result.total, 2);
    expect(result.completed, 2);
    expect(result.failed, 0);
    expect(sending, [1, 2]);
    expect(completed, [1, 2]);
    expect(failed, isEmpty);
  });

  test(
    'marca como fallida una operación rechazada por el transporte',
    () async {
      final completed = <int>[];
      final failed = <int>[];

      final engine = SyncEngine(
        transport: SimulatedSyncTransport(
          delay: Duration.zero,
          failurePredicate: (item) => item.id == 2,
        ),
        loadPending: () => [operation(1), operation(2)],
        markAsSending: (_) async {},
        markAsCompleted: (id) async => completed.add(id),
        markAsFailed: (id) async => failed.add(id),
      );

      final result = await engine.synchronizePending();

      expect(result.completed, 1);
      expect(result.failed, 1);
      expect(completed, [1]);
      expect(failed, [2]);
    },
  );
}
