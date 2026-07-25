enum AgendaEventType {
  ticket,
  hotelCheckIn,
  hotelCheckOut,
  transfer,
  task,
}

extension AgendaEventTypeLabel on AgendaEventType {
  String get label {
    switch (this) {
      case AgendaEventType.ticket:
        return 'Pasaje';
      case AgendaEventType.hotelCheckIn:
        return 'Check-in';
      case AgendaEventType.hotelCheckOut:
        return 'Check-out';
      case AgendaEventType.transfer:
        return 'Traslado';
      case AgendaEventType.task:
        return 'Tarea';
    }
  }
}

enum AgendaEventStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

extension AgendaEventStatusLabel on AgendaEventStatus {
  String get label {
    switch (this) {
      case AgendaEventStatus.pending:
        return 'Pendiente';
      case AgendaEventStatus.confirmed:
        return 'Confirmado';
      case AgendaEventStatus.completed:
        return 'Completado';
      case AgendaEventStatus.cancelled:
        return 'Cancelado';
    }
  }
}

class AgendaEvent {
  final String id;
  final AgendaEventType type;
  final String workerId;
  final String title;
  final String subtitle;
  final DateTime date;
  final String time;
  final String location;
  final AgendaEventStatus status;
  final String sourceId;

  const AgendaEvent({
    required this.id,
    required this.type,
    required this.workerId,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.sourceId,
  });

  DateTime get dateTime {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }
}
