class Vehicle {
  final String id;
  final String operationId;
  String identifier;
  String type;
  String licensePlate;
  int capacity;
  String driverName;
  String driverPhone;
  String providerId;
  String status;
  String notes;
  final DateTime createdAt;
  DateTime updatedAt;
  String createdBy;

  Vehicle({
    required this.id,
    required this.operationId,
    required this.identifier,
    required this.type,
    required this.licensePlate,
    required this.capacity,
    required this.driverName,
    required this.driverPhone,
    required this.providerId,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationId': operationId,
        'identifier': identifier,
        'type': type,
        'licensePlate': licensePlate,
        'capacity': capacity,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'providerId': providerId,
        'status': status,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String? ?? '',
        operationId: json['operationId'] as String? ?? '',
        identifier: json['identifier'] as String? ?? '',
        type: json['type'] as String? ?? '',
        licensePlate: json['licensePlate'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        driverName: json['driverName'] as String? ?? '',
        driverPhone: json['driverPhone'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        status: json['status'] as String? ?? 'Disponible',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        createdBy: json['createdBy'] as String? ?? '',
      );
}
