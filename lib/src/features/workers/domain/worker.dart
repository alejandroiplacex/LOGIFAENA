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

class Worker {
  final String id;
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

  Worker({
    required this.id,
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
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'id': id,
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
      };

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'] as String,
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
        status: WorkerStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => WorkerStatus.pending,
        ),
      );
}

