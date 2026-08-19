import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/database/database_service.dart';
import '../../../core/sync/audit_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../domain/worker.dart';

abstract class WorkerRepository {
  List<Worker> getAll();

  void add(Worker worker);

  void addAll(List<Worker> workers);

  ({int created, int updated}) importAll(
    List<Worker> workers, {
    required bool updateExisting,
  });

  void update(Worker worker);

  void delete(String id);

  void clear();

  ({int created, int updated, int deleted}) applyServerChanges(
    List<Worker> workers, {
    Set<String> deletedIds = const <String>{},
  });
}

class InMemoryWorkerRepository implements WorkerRepository {
  InMemoryWorkerRepository._() {
    final saved = DatabaseService.instance.readList('logifaena_workers');

    if (saved.isNotEmpty) {
      _workers
        ..clear()
        ..addAll(saved.map(Worker.fromJson));
    }
  }

  static final InMemoryWorkerRepository instance = InMemoryWorkerRepository._();

  final List<Worker> _workers = <Worker>[];

  void _persist() {
    unawaited(
      DatabaseService.instance.writeList(
        'logifaena_workers',
        _workers.map((worker) => worker.toJson()).toList(),
      ),
    );
  }

  void _enqueueSync({
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    unawaited(
      _enqueueSyncSafely(
        entityId: entityId,
        operation: operation,
        payload: payload,
      ),
    );
  }

  Future<void> _enqueueSyncSafely({
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await SyncQueueService.instance.enqueue(
        entityType: 'worker',
        entityId: entityId,
        operation: operation,
        payload: payload,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'No fue posible agregar la operación del trabajador '
        'a la cola de sincronización: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _recordAudit({
    required String action,
    required Map<String, dynamic> details,
  }) {
    unawaited(_recordAuditSafely(action: action, details: details));
  }

  Future<void> _recordAuditSafely({
    required String action,
    required Map<String, dynamic> details,
  }) async {
    try {
      await AuditService.instance.record(
        action: action,
        entityType: 'worker',
        details: jsonEncode(details),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'No fue posible registrar la auditoría del trabajador: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  List<Worker> getAll() => List.unmodifiable(_workers);

  @override
  void add(Worker worker) {
    _workers.add(worker);
    _persist();

    _enqueueSync(
      entityId: worker.id,
      operation: 'create',
      payload: worker.toJson(),
    );

    _recordAudit(
      action: 'create',
      details: <String, dynamic>{
        'workerId': worker.id,
        'rut': worker.rut,
        'fullName': worker.fullName,
      },
    );
  }

  @override
  void addAll(List<Worker> workers) {
    if (workers.isEmpty) return;

    _workers.addAll(workers);
    _persist();

    for (final worker in workers) {
      _enqueueSync(
        entityId: worker.id,
        operation: 'create',
        payload: worker.toJson(),
      );
    }

    _recordAudit(
      action: 'create_bulk',
      details: <String, dynamic>{
        'created': workers.length,
        'workerIds': workers.map((worker) => worker.id).toList(),
      },
    );
  }

  @override
  ({int created, int updated}) importAll(
    List<Worker> workers, {
    required bool updateExisting,
  }) {
    var created = 0;
    var updated = 0;

    for (final worker in workers) {
      final normalizedRut = _normalizeRut(worker.rut);

      final index = _workers.indexWhere(
        (existingWorker) => _normalizeRut(existingWorker.rut) == normalizedRut,
      );

      if (updateExisting && index != -1) {
        _workers[index] = worker;
        updated++;

        _enqueueSync(
          entityId: worker.id,
          operation: 'update',
          payload: worker.toJson(),
        );
      } else {
        _workers.add(worker);
        created++;

        _enqueueSync(
          entityId: worker.id,
          operation: 'create',
          payload: worker.toJson(),
        );
      }
    }

    _persist();

    _recordAudit(
      action: 'import',
      details: <String, dynamic>{
        'received': workers.length,
        'created': created,
        'updated': updated,
        'updateExisting': updateExisting,
      },
    );

    return (created: created, updated: updated);
  }

  @override
  void update(Worker worker) {
    final index = _workers.indexWhere(
      (existingWorker) => existingWorker.id == worker.id,
    );

    if (index == -1) return;

    _workers[index] = worker;
    _persist();

    _enqueueSync(
      entityId: worker.id,
      operation: 'update',
      payload: worker.toJson(),
    );

    _recordAudit(
      action: 'update',
      details: <String, dynamic>{
        'workerId': worker.id,
        'rut': worker.rut,
        'fullName': worker.fullName,
        'status': worker.status.name,
      },
    );
  }

  @override
  void delete(String id) {
    final index = _workers.indexWhere((worker) => worker.id == id);

    if (index == -1) return;

    final deletedWorker = _workers[index];

    _workers.removeAt(index);
    _persist();

    _enqueueSync(
      entityId: id,
      operation: 'delete',
      payload: <String, dynamic>{'id': id},
    );

    _recordAudit(
      action: 'delete',
      details: <String, dynamic>{
        'workerId': deletedWorker.id,
        'rut': deletedWorker.rut,
        'fullName': deletedWorker.fullName,
      },
    );
  }

  @override
  void clear() {
    _workers.clear();
    _persist();
  }

  @override
  ({int created, int updated, int deleted}) applyServerChanges(
    List<Worker> workers, {
    Set<String> deletedIds = const <String>{},
  }) {
    var created = 0;
    var updated = 0;
    var deleted = 0;

    for (final worker in workers) {
      final index = _workers.indexWhere(
        (existingWorker) => existingWorker.id == worker.id,
      );

      if (index == -1) {
        _workers.add(worker);
        created++;
      } else {
        _workers[index] = worker;
        updated++;
      }
    }

    for (final deletedId in deletedIds) {
      final index = _workers.indexWhere((worker) => worker.id == deletedId);

      if (index == -1) {
        continue;
      }

      _workers.removeAt(index);
      deleted++;
    }

    _persist();

    return (created: created, updated: updated, deleted: deleted);
  }

  String _normalizeRut(String rut) {
    return rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  }
}
