class OperationNote {
  final String id;
  final String operationId;
  final String? workerId;
  String category;
  String message;
  String priority;
  final DateTime createdAt;
  DateTime updatedAt;
  String createdBy;

  OperationNote({
    required this.id,
    required this.operationId,
    required this.workerId,
    required this.category,
    required this.message,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationId': operationId,
        'workerId': workerId,
        'category': category,
        'message': message,
        'priority': priority,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory OperationNote.fromJson(Map<String, dynamic> json) => OperationNote(
        id: json['id'] as String? ?? '',
        operationId: json['operationId'] as String? ?? '',
        workerId: json['workerId'] as String?,
        category: json['category'] as String? ?? '',
        message: json['message'] as String? ?? '',
        priority: json['priority'] as String? ?? 'Informativa',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        createdBy: json['createdBy'] as String? ?? '',
      );
}
