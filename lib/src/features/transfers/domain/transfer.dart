enum TransferVehicleType { bus, van, pickup, taxi }

extension TransferVehicleTypeLabel on TransferVehicleType {
  String get label {
    switch (this) {
      case TransferVehicleType.bus:
        return 'Bus';
      case TransferVehicleType.van:
        return 'Van';
      case TransferVehicleType.pickup:
        return 'Camioneta';
      case TransferVehicleType.taxi:
        return 'Taxi';
    }
  }
}

enum TransferStatus { scheduled, boarding, onRoute, completed, cancelled }

extension TransferStatusLabel on TransferStatus {
  String get label {
    switch (this) {
      case TransferStatus.scheduled:
        return 'Programado';
      case TransferStatus.boarding:
        return 'Embarcando';
      case TransferStatus.onRoute:
        return 'En ruta';
      case TransferStatus.completed:
        return 'Finalizado';
      case TransferStatus.cancelled:
        return 'Cancelado';
    }
  }
}

class Transfer {
  final String id;
  String code;
  DateTime date;
  String departureTime;
  String estimatedArrivalTime;
  String origin;
  String destination;
  String routeDescription;
  TransferVehicleType vehicleType;
  String vehicleIdentifier;
  String licensePlate;
  int capacity;
  String driverName;
  String driverPhone;
  String providerCompany;
  List<String> workerIds;
  String notes;
  TransferStatus status;

  Transfer({
    required this.id,
    required this.code,
    required this.date,
    required this.departureTime,
    required this.estimatedArrivalTime,
    required this.origin,
    required this.destination,
    required this.routeDescription,
    required this.vehicleType,
    required this.vehicleIdentifier,
    required this.licensePlate,
    required this.capacity,
    required this.driverName,
    required this.driverPhone,
    required this.providerCompany,
    required this.workerIds,
    required this.notes,
    required this.status,
  });

  int get availableSeats => capacity - workerIds.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'date': date.toIso8601String(),
    'departureTime': departureTime,
    'estimatedArrivalTime': estimatedArrivalTime,
    'origin': origin,
    'destination': destination,
    'routeDescription': routeDescription,
    'vehicleType': vehicleType.name,
    'vehicleIdentifier': vehicleIdentifier,
    'licensePlate': licensePlate,
    'capacity': capacity,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'providerCompany': providerCompany,
    'workerIds': workerIds,
    'notes': notes,
    'status': status.name,
  };

  factory Transfer.fromJson(Map<String, dynamic> json) => Transfer(
    id: json['id'] as String,
    code: json['code'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    departureTime: json['departureTime'] as String? ?? '',
    estimatedArrivalTime: json['estimatedArrivalTime'] as String? ?? '',
    origin: json['origin'] as String? ?? '',
    destination: json['destination'] as String? ?? '',
    routeDescription: json['routeDescription'] as String? ?? '',
    vehicleType: TransferVehicleType.values.firstWhere(
      (value) => value.name == json['vehicleType'],
      orElse: () => TransferVehicleType.van,
    ),
    vehicleIdentifier: json['vehicleIdentifier'] as String? ?? '',
    licensePlate: json['licensePlate'] as String? ?? '',
    capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    driverName: json['driverName'] as String? ?? '',
    driverPhone: json['driverPhone'] as String? ?? '',
    providerCompany: json['providerCompany'] as String? ?? '',
    workerIds: (json['workerIds'] as List<dynamic>? ?? []).cast<String>(),
    notes: json['notes'] as String? ?? '',
    status: TransferStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => TransferStatus.scheduled,
    ),
  );
}
