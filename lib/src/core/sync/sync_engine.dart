import 'pending_sync_operation.dart';
import 'simulated_sync_transport.dart';
import 'sync_queue_service.dart';
import 'sync_result.dart';
import 'sync_transport.dart';
import 'sync_transport_factory.dart';

typedef PendingOperationsLoader = List<PendingSyncOperation> Function();
typedef SyncOperationUpdater = Future<void> Function(int id);

class SyncEngine {
  SyncEngine({
    SyncTransport? transport,
    PendingOperationsLoader? loadPending,
    SyncOperationUpdater? markAsSending,
    SyncOperationUpdater? markAsCompleted,
    SyncOperationUpdater? markAsFailed,
  }) : _transport = transport ?? const SimulatedSyncTransport(),
       _loadPending = loadPending ?? SyncQueueService.instance.getPending,
       _markAsSending =
           markAsSending ?? SyncQueueService.instance.markAsSending,
       _markAsCompleted =
           markAsCompleted ?? SyncQueueService.instance.markAsCompleted,
       _markAsFailed = markAsFailed ?? SyncQueueService.instance.markAsFailed;

  static final SyncEngine instance = SyncEngine(
    transport: SyncTransportFactory.create(),
  );

  final SyncTransport _transport;
  final PendingOperationsLoader _loadPending;
  final SyncOperationUpdater _markAsSending;
  final SyncOperationUpdater _markAsCompleted;
  final SyncOperationUpdater _markAsFailed;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<SyncRunResult> synchronizePending() async {
    if (_isRunning) {
      throw StateError('Ya existe una sincronización en curso.');
    }

    _isRunning = true;
    final startedAt = DateTime.now().toUtc();

    var completed = 0;
    var failed = 0;
    var skipped = 0;

    try {
      final operations = List<PendingSyncOperation>.from(_loadPending());

      for (final operation in operations) {
        final id = operation.id;
        if (id == null) {
          skipped++;
          continue;
        }

        try {
          await _markAsSending(id);
          await _transport.send(operation);
          await _markAsCompleted(id);
          completed++;
        } catch (_) {
          failed++;
          try {
            await _markAsFailed(id);
          } catch (_) {
            // Conserva el fallo original aunque no pueda actualizarse SQLite.
          }
        }
      }

      return SyncRunResult(
        startedAt: startedAt,
        finishedAt: DateTime.now().toUtc(),
        total: operations.length,
        completed: completed,
        failed: failed,
        skipped: skipped,
      );
    } finally {
      _isRunning = false;
    }
  }
}
