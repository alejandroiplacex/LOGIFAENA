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

/// Estado individual de cada trabajador dentro de un traslado.
enum TransferPassengerStatus { pending, boarded, arrived }

extension TransferPassengerStatusLabel on TransferPassengerStatus {
  String get label {
    switch (this) {
      case TransferPassengerStatus.pending:
        return 'Pendiente';
      case TransferPassengerStatus.boarded:
        return 'Abordó';
      case TransferPassengerStatus.arrived:
        return 'Llegó';
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

  /// Estado individual de cada pasajero.
  ///
  /// Ejemplo:
  /// {
  ///   'worker-001': TransferPassengerStatus.arrived,
  ///   'worker-002': TransferPassengerStatus.pending,
  /// }
  Map<String, TransferPassengerStatus> passengerStatuses;

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
    Map<String, TransferPassengerStatus>? passengerStatuses,
    required this.notes,
    required this.status,
  }) : passengerStatuses = passengerStatuses ?? {};

  int get availableSeats => capacity - workerIds.length;

  /// Cantidad de trabajadores esperados.
  int get expectedPassengers => workerIds.length;

  /// Cantidad que ya abordó el vehículo.
  int get boardedPassengers => workerIds.where((workerId) {
    final passengerStatus = statusForWorker(workerId);

    return passengerStatus == TransferPassengerStatus.boarded ||
        passengerStatus == TransferPassengerStatus.arrived;
  }).length;

  /// Cantidad que confirmó llegada al destino.
  int get arrivedPassengers => workerIds.where((workerId) {
    return statusForWorker(workerId) == TransferPassengerStatus.arrived;
  }).length;

  /// Cantidad que todavía no confirma llegada.
  int get pendingPassengers => expectedPassengers - arrivedPassengers;

  /// Devuelve el estado de un trabajador.
  ///
  /// Si el traslado fue creado antes de incorporar esta función,
  /// automáticamente se considera Pendiente.
  TransferPassengerStatus statusForWorker(String workerId) {
    return passengerStatuses[workerId] ?? TransferPassengerStatus.pending;
  }

  /// Cambia el estado individual de un trabajador.
  void setWorkerStatus(
    String workerId,
    TransferPassengerStatus passengerStatus,
  ) {
    if (!workerIds.contains(workerId)) return;

    passengerStatuses[workerId] = passengerStatus;
  }

  /// Elimina estados de trabajadores que ya no pertenecen
  /// al traslado.
  void cleanPassengerStatuses() {
    passengerStatuses.removeWhere(
      (workerId, _) => !workerIds.contains(workerId),
    );
  }

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
    'passengerStatuses': passengerStatuses.map(
      (workerId, passengerStatus) => MapEntry(workerId, passengerStatus.name),
    ),
    'notes': notes,
    'status': status.name,
  };

  factory Transfer.fromJson(Map<String, dynamic> json) {
    final rawPassengerStatuses =
        json['passengerStatuses'] as Map<String, dynamic>? ?? {};

    final parsedPassengerStatuses = <String, TransferPassengerStatus>{};

    for (final entry in rawPassengerStatuses.entries) {
      parsedPassengerStatuses[entry.key] = TransferPassengerStatus.values
          .firstWhere(
            (value) => value.name == entry.value,
            orElse: () => TransferPassengerStatus.pending,
          );
    }

    return Transfer(
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
      capacity: json['capacity'] as int? ?? 0,
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '',
      providerCompany: json['providerCompany'] as String? ?? '',
      workerIds: (json['workerIds'] as List<dynamic>? ?? []).cast<String>(),
      passengerStatuses: parsedPassengerStatuses,
      notes: json['notes'] as String? ?? '',
      status: TransferStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => TransferStatus.scheduled,
      ),
    );
  }
}
