enum WorkerStatus {
  pending,
  ticketIssued,
  traveling,
  lodging,
  transfer,
  atSite,
  finished,
  cancelled,
}

extension WorkerStatusLabel on WorkerStatus {
  String get label {
    switch (this) {
      case WorkerStatus.pending:
        return 'Pendiente';
      case WorkerStatus.ticketIssued:
        return 'Pasaje emitido';
      case WorkerStatus.traveling:
        return 'En viaje';
      case WorkerStatus.lodging:
        return 'En alojamiento';
      case WorkerStatus.transfer:
        return 'En traslado';
      case WorkerStatus.atSite:
        return 'En faena';
      case WorkerStatus.finished:
        return 'Finalizado';
      case WorkerStatus.cancelled:
        return 'Cancelado';
    }
  }
}

enum PresentationStatus { pending, presented, late, absent }

enum WorkerOperationalLocation {
  unknown,
  originCity,
  travelingToCaldera,
  hotel,
  travelingToSite,
  site,
  returningToHotel,
  returningHome,
}

extension WorkerOperationalLocationLabel on WorkerOperationalLocation {
  String get label {
    switch (this) {
      case WorkerOperationalLocation.unknown:
        return 'Sin ubicación';
      case WorkerOperationalLocation.originCity:
        return 'Ciudad de origen';
      case WorkerOperationalLocation.travelingToCaldera:
        return 'En viaje a Caldera';
      case WorkerOperationalLocation.hotel:
        return 'Hotel Vitrali';
      case WorkerOperationalLocation.travelingToSite:
        return 'En traslado a faena';
      case WorkerOperationalLocation.site:
        return 'Manto Verde';
      case WorkerOperationalLocation.returningToHotel:
        return 'En retorno al hotel';
      case WorkerOperationalLocation.returningHome:
        return 'En bajada de turno';
    }
  }
}

extension PresentationStatusLabel on PresentationStatus {
  String get label {
    switch (this) {
      case PresentationStatus.pending:
        return 'Pendiente de presentación';
      case PresentationStatus.presented:
        return 'Presentado';
      case PresentationStatus.late:
        return 'Presentación tardía';
      case PresentationStatus.absent:
        return 'No se presentó';
    }
  }
}

class Worker {
  final String id;

  String workerCode;
  String qrToken;
  String rut;
  String firstName;
  String lastName;
  String company;
  String role;
  String project;
  String shift;
  String supervisor;
  String city;
  String phone;
  String email;
  String emergencyContact;
  String emergencyPhone;
  String hotel;
  String room;
  String ticket;
  String transfer;
  String notes;
  WorkerStatus status;
  PresentationStatus presentationStatus;
  WorkerOperationalLocation operationalLocation;
  DateTime? operationalLocationAt;
  DateTime? presentationAt;
  String presentationNote;

  Worker({
    required this.id,
    this.workerCode = '',
    this.qrToken = '',
    required this.rut,
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.role,
    required this.project,
    required this.shift,
    required this.supervisor,
    required this.city,
    required this.phone,
    required this.email,
    required this.emergencyContact,
    required this.emergencyPhone,
    required this.hotel,
    required this.room,
    required this.ticket,
    required this.transfer,
    required this.notes,
    required this.status,
    this.presentationStatus = PresentationStatus.pending,
    this.operationalLocation = WorkerOperationalLocation.unknown,
    this.operationalLocationAt,
    this.presentationAt,
    this.presentationNote = '',
  });

  String get fullName => '$firstName $lastName'.trim();

  String get qrData {
    if (qrToken.trim().isEmpty) {
      return '';
    }

    return 'logifaena:worker:${qrToken.trim()}';
  }

  bool get hasQrIdentity =>
      workerCode.trim().isNotEmpty && qrToken.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workerCode': workerCode,
    'qrToken': qrToken,
    'rut': rut,
    'firstName': firstName,
    'lastName': lastName,
    'company': company,
    'role': role,
    'project': project,
    'shift': shift,
    'supervisor': supervisor,
    'city': city,
    'phone': phone,
    'email': email,
    'emergencyContact': emergencyContact,
    'emergencyPhone': emergencyPhone,
    'hotel': hotel,
    'room': room,
    'ticket': ticket,
    'transfer': transfer,
    'notes': notes,
    'status': status.name,
    'presentationStatus': presentationStatus.name,
    'operationalLocation': operationalLocation.name,
    'operationalLocationAt': operationalLocationAt?.toIso8601String(),
    'presentationAt': presentationAt?.toIso8601String(),
    'presentationNote': presentationNote,
  };
  static WorkerStatus _statusFromJson(dynamic value) {
    final status = value?.toString().trim().toLowerCase() ?? '';

    switch (status) {
      case 'pending':
      case 'pendiente':
        return WorkerStatus.pending;

      case 'ticketissued':
      case 'ticket_issued':
      case 'pasaje_emitido':
        return WorkerStatus.ticketIssued;

      case 'traveling':
      case 'travelling':
      case 'en_viaje':
        return WorkerStatus.traveling;

      case 'lodging':
      case 'alojado':
      case 'en_alojamiento':
        return WorkerStatus.lodging;

      case 'transfer':
      case 'en_traslado':
        return WorkerStatus.transfer;

      case 'active':
      case 'atsite':
      case 'at_site':
      case 'en_faena':
        return WorkerStatus.atSite;

      case 'finished':
      case 'finalizado':
        return WorkerStatus.finished;

      case 'cancelled':
      case 'canceled':
      case 'cancelado':
        return WorkerStatus.cancelled;

      default:
        return WorkerStatus.pending;
    }
  }

  static PresentationStatus _presentationStatusFromJson(dynamic value) {
    final status = value?.toString().trim().toLowerCase() ?? '';

    switch (status) {
      case 'presented':
      case 'presentado':
        return PresentationStatus.presented;

      case 'late':
      case 'tardio':
      case 'tardia':
        return PresentationStatus.late;

      case 'absent':
      case 'ausente':
      case 'no_se_presento':
        return PresentationStatus.absent;

      case 'pending':
      case 'pendiente':
      default:
        return PresentationStatus.pending;
    }
  }

  static WorkerOperationalLocation _operationalLocationFromJson(dynamic value) {
    final location = value?.toString().trim();

    return WorkerOperationalLocation.values.firstWhere(
      (item) => item.name == location,
      orElse: () => WorkerOperationalLocation.unknown,
    );
  }

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
    id: json['externalId']?.toString().trim().isNotEmpty == true
        ? json['externalId'].toString()
        : json['id']?.toString() ?? '',
    workerCode: json['workerCode'] as String? ?? '',
    qrToken: json['qrToken'] as String? ?? '',
    rut: json['rut'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    company: json['company'] as String? ?? '',
    role: json['role'] as String? ?? '',
    project: json['project'] as String? ?? '',
    shift: json['shift'] as String? ?? '',
    supervisor: json['supervisor'] as String? ?? '',
    city: json['city'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    emergencyContact: json['emergencyContact'] as String? ?? '',
    emergencyPhone: json['emergencyPhone'] as String? ?? '',
    hotel: json['hotel'] as String? ?? '',
    room: json['room'] as String? ?? '',
    ticket: json['ticket'] as String? ?? '',
    transfer: json['transfer'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    status: _statusFromJson(json['status']),
    presentationStatus: _presentationStatusFromJson(json['presentationStatus']),
    operationalLocation: _operationalLocationFromJson(
      json['operationalLocation'],
    ),
    operationalLocationAt: DateTime.tryParse(
      json['operationalLocationAt']?.toString() ?? '',
    ),
    presentationAt: DateTime.tryParse(json['presentationAt']?.toString() ?? ''),
    presentationNote: json['presentationNote'] as String? ?? '',
  );
}
