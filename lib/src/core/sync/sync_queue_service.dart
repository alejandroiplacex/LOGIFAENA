import 'dart:convert';

import '../database/database_service.dart';
import 'pending_sync_operation.dart';
import 'sync_status.dart';

/// Administra las operaciones locales pendientes de sincronización.
class SyncQueueService {
  SyncQueueService._();

  static final SyncQueueService instance = SyncQueueService._();

  final DatabaseService _database = DatabaseService.instance;

  /// Agrega una operación nueva a la cola y devuelve su identificador local.
  Future<int> enqueue({
    required String entityType,
    String? entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    return _database.enqueueSyncOperation(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(payload),
      createdAt: DateTime.now().toUtc().toIso8601String(),
      status: SyncStatus.pending.databaseValue,
    );
  }

  /// Obtiene todas las operaciones almacenadas en la cola.
  List<PendingSyncOperation> getAll() {
    return _database
        .readSyncQueue()
        .map(PendingSyncOperation.fromDatabaseRow)
        .toList(growable: false);
  }

  /// Obtiene solamente las operaciones pendientes.
  List<PendingSyncOperation> getPending() {
    return getByStatus(SyncStatus.pending);
  }

  /// Obtiene las operaciones que coinciden con un estado determinado.
  List<PendingSyncOperation> getByStatus(SyncStatus status) {
    return _database
        .readSyncQueue(status: status.databaseValue)
        .map(PendingSyncOperation.fromDatabaseRow)
        .toList(growable: false);
  }

  /// Marca una operación como enviada actualmente.
  Future<void> markAsSending(int id) {
    return _database.updateSyncOperationStatus(
      id,
      SyncStatus.sending.databaseValue,
    );
  }

  /// Marca una operación como completada.
  Future<void> markAsCompleted(int id) {
    return _database.updateSyncOperationStatus(
      id,
      SyncStatus.completed.databaseValue,
    );
  }

  /// Marca una operación como fallida e incrementa sus intentos.
  Future<void> markAsFailed(int id) {
    return _database.updateSyncOperationStatus(
      id,
      SyncStatus.failed.databaseValue,
      incrementAttempts: true,
    );
  }

  /// Devuelve una operación fallida al estado pendiente.
  Future<void> retry(int id) {
    return _database.updateSyncOperationStatus(
      id,
      SyncStatus.pending.databaseValue,
    );
  }

  /// Elimina una operación de la cola.
  Future<void> remove(int id) {
    return _database.deleteSyncOperation(id);
  }
}
