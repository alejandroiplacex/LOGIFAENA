import 'dart:convert';

import 'sync_status.dart';

/// Representa una modificación local pendiente de envío al servidor.
class PendingSyncOperation {
  const PendingSyncOperation({
    this.id,
    required this.entityType,
    this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.status = SyncStatus.pending,
  });

  /// Identificador generado por SQLite.
  final int? id;

  /// Tipo de entidad modificada, por ejemplo: worker, ticket o transfer.
  final String entityType;

  /// Identificador de la entidad modificada.
  final String? entityId;

  /// Operación realizada: create, update o delete.
  final String operation;

  /// Información que posteriormente será enviada al servidor.
  final Map<String, dynamic> payload;

  /// Fecha en que se creó la operación local.
  final DateTime createdAt;

  /// Cantidad de intentos de sincronización.
  final int attempts;

  /// Estado actual de la operación.
  final SyncStatus status;

  PendingSyncOperation copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? operation,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attempts,
    SyncStatus? status,
  }) {
    return PendingSyncOperation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'operation': operation,
    'payload': payload,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'attempts': attempts,
    'status': status.name,
  };

  Map<String, Object?> toDatabaseParameters() => <String, Object?>{
    'entity_type': entityType,
    'entity_id': entityId,
    'operation': operation,
    'payload': jsonEncode(payload),
    'created_at': createdAt.toUtc().toIso8601String(),
    'attempts': attempts,
    'status': status.databaseValue,
  };

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: (json['id'] as num?)?.toInt(),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String?,
      operation: json['operation'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      status: SyncStatus.fromDatabaseValue(
        json['status'] as String? ?? SyncStatus.pending.name,
      ),
    );
  }

  factory PendingSyncOperation.fromDatabaseRow(Map<String, Object?> row) {
    final decodedPayload = jsonDecode(row['payload'] as String);

    return PendingSyncOperation(
      id: (row['id'] as num).toInt(),
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String?,
      operation: row['operation'] as String,
      payload: Map<String, dynamic>.from(decodedPayload as Map),
      createdAt: DateTime.parse(row['created_at'] as String),
      attempts: (row['attempts'] as num).toInt(),
      status: SyncStatus.fromDatabaseValue(row['status'] as String),
    );
  }
}
