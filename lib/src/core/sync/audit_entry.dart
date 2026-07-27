/// Representa una acción registrada en el historial local.
class AuditEntry {
  const AuditEntry({
    this.id,
    required this.occurredAt,
    required this.action,
    required this.entityType,
    this.details,
  });

  /// Identificador generado por el almacenamiento local.
  final int? id;

  /// Momento en que ocurrió la acción.
  final DateTime occurredAt;

  /// Acción realizada, por ejemplo: create, update, delete o import.
  final String action;

  /// Entidad afectada, por ejemplo: worker, ticket o transfer.
  final String entityType;

  /// Información adicional de la acción.
  final String? details;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'action': action,
    'entityType': entityType,
    'details': details,
  };

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: (json['id'] as num?)?.toInt(),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      details: json['details'] as String?,
    );
  }

  factory AuditEntry.fromDatabaseRow(Map<String, Object?> row) {
    return AuditEntry(
      id: (row['id'] as num).toInt(),
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      action: row['action'] as String,
      entityType: row['entity_type'] as String,
      details: row['details'] as String?,
    );
  }
}
