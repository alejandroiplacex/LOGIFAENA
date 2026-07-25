/// Representa una modificación local pendiente de envío al servidor.
class PendingSyncOperation {
  const PendingSyncOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id;
  final String entity;
  final String entityId;
  final String action;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'entity': entity,
        'entityId': entityId,
        'action': action,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      entity: json['entity'] as String,
      entityId: json['entityId'] as String,
      action: json['action'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}
