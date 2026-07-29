enum TicketStatus { requested, issued, rescheduled, cancelled }

extension TicketStatusLabel on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.requested:
        return 'Solicitado';
      case TicketStatus.issued:
        return 'Emitido';
      case TicketStatus.rescheduled:
        return 'Reprogramado';
      case TicketStatus.cancelled:
        return 'Cancelado';
    }
  }
}

enum TicketType { flight, bus }

extension TicketTypeLabel on TicketType {
  String get label {
    switch (this) {
      case TicketType.flight:
        return 'Aéreo';
      case TicketType.bus:
        return 'Bus';
    }
  }
}

class Ticket {
  final String id;
  String workerId;
  TicketType type;
  String company;
  String serviceNumber;
  String bookingCode;
  String origin;
  String destination;
  DateTime travelDate;
  String travelTime;
  String baggage;
  String seat;
  String notes;
  TicketStatus status;

  Ticket({
    required this.id,
    required this.workerId,
    required this.type,
    required this.company,
    required this.serviceNumber,
    required this.bookingCode,
    required this.origin,
    required this.destination,
    required this.travelDate,
    required this.travelTime,
    required this.baggage,
    required this.seat,
    required this.notes,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'workerId': workerId,
    'type': type.name,
    'company': company,
    'serviceNumber': serviceNumber,
    'bookingCode': bookingCode,
    'origin': origin,
    'destination': destination,
    'travelDate': travelDate.toIso8601String(),
    'travelTime': travelTime,
    'baggage': baggage,
    'seat': seat,
    'notes': notes,
    'status': status.name,
  };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id'] as String,
    workerId: json['workerId'] as String? ?? '',
    type: TicketType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => TicketType.flight,
    ),
    company: json['company'] as String? ?? '',
    serviceNumber: json['serviceNumber'] as String? ?? '',
    bookingCode: json['bookingCode'] as String? ?? '',
    origin: json['origin'] as String? ?? '',
    destination: json['destination'] as String? ?? '',
    travelDate:
        DateTime.tryParse(json['travelDate'] as String? ?? '') ??
        DateTime.now(),
    travelTime: json['travelTime'] as String? ?? '',
    baggage: json['baggage'] as String? ?? '',
    seat: json['seat'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    status: TicketStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => TicketStatus.requested,
    ),
  );
}
