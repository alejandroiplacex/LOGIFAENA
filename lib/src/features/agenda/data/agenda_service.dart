import '../../hotels/data/hotel_repository.dart';
import '../../hotels/domain/hotel_assignment.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../tickets/domain/ticket.dart';
import '../../transfers/data/transfer_repository.dart';
import '../../transfers/domain/transfer.dart';
import '../domain/agenda_event.dart';

class AgendaService {
  AgendaService._();

  static final AgendaService instance = AgendaService._();

  final ticketRepository = InMemoryTicketRepository.instance;
  final hotelRepository = InMemoryHotelRepository.instance;
  final transferRepository = InMemoryTransferRepository.instance;

  List<AgendaEvent> getEvents() {
    final events = <AgendaEvent>[
      ...ticketRepository.getAll().map(_ticketEvent),
      ...hotelRepository.getAll().expand(_hotelEvents),
      ...transferRepository.getAll().expand(_transferEvents),
    ];

    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return events;
  }

  AgendaEvent _ticketEvent(Ticket ticket) {
    return AgendaEvent(
      id: 'ticket-${ticket.id}',
      type: AgendaEventType.ticket,
      workerId: ticket.workerId,
      title: ticket.type == TicketType.flight ? 'Viaje aéreo' : 'Viaje en bus',
      subtitle: '${ticket.company} ${ticket.serviceNumber}'.trim(),
      date: ticket.travelDate,
      time: ticket.travelTime.isEmpty ? '00:00' : ticket.travelTime,
      location: '${ticket.origin} → ${ticket.destination}',
      status: _ticketStatus(ticket.status),
      sourceId: ticket.id,
    );
  }

  Iterable<AgendaEvent> _hotelEvents(HotelAssignment assignment) sync* {
    yield AgendaEvent(
      id: 'hotel-in-${assignment.id}',
      type: AgendaEventType.hotelCheckIn,
      workerId: assignment.workerId,
      title: 'Check-in de alojamiento',
      subtitle: assignment.hotelName,
      date: assignment.checkInDate,
      time: '15:00',
      location: '${assignment.city} · Hab. ${assignment.room}',
      status: _checkInStatus(assignment.status),
      sourceId: assignment.id,
    );

    yield AgendaEvent(
      id: 'hotel-out-${assignment.id}',
      type: AgendaEventType.hotelCheckOut,
      workerId: assignment.workerId,
      title: 'Check-out de alojamiento',
      subtitle: assignment.hotelName,
      date: assignment.checkOutDate,
      time: '12:00',
      location: '${assignment.city} · Hab. ${assignment.room}',
      status: _checkOutStatus(assignment.status),
      sourceId: assignment.id,
    );
  }

  Iterable<AgendaEvent> _transferEvents(Transfer transfer) sync* {
    for (final workerId in transfer.workerIds) {
      yield AgendaEvent(
        id: 'transfer-${transfer.id}-$workerId',
        type: AgendaEventType.transfer,
        workerId: workerId,
        title: 'Traslado ${transfer.vehicleType.label.toLowerCase()}',
        subtitle:
            '${transfer.code} · ${transfer.vehicleIdentifier} · '
            '${transfer.driverName}',
        date: transfer.date,
        time: transfer.departureTime.isEmpty ? '00:00' : transfer.departureTime,
        location: '${transfer.origin} → ${transfer.destination}',
        status: _transferStatus(transfer.status),
        sourceId: transfer.id,
      );
    }
  }

  AgendaEventStatus _transferStatus(TransferStatus status) {
    switch (status) {
      case TransferStatus.scheduled:
      case TransferStatus.boarding:
        return AgendaEventStatus.confirmed;
      case TransferStatus.onRoute:
        return AgendaEventStatus.confirmed;
      case TransferStatus.completed:
        return AgendaEventStatus.completed;
      case TransferStatus.cancelled:
        return AgendaEventStatus.cancelled;
    }
  }

  AgendaEventStatus _ticketStatus(TicketStatus status) {
    switch (status) {
      case TicketStatus.requested:
        return AgendaEventStatus.pending;
      case TicketStatus.issued:
      case TicketStatus.rescheduled:
        return AgendaEventStatus.confirmed;
      case TicketStatus.cancelled:
        return AgendaEventStatus.cancelled;
    }
  }

  AgendaEventStatus _checkInStatus(HotelStatus status) {
    switch (status) {
      case HotelStatus.requested:
        return AgendaEventStatus.pending;
      case HotelStatus.confirmed:
        return AgendaEventStatus.confirmed;
      case HotelStatus.checkedIn:
      case HotelStatus.checkedOut:
        return AgendaEventStatus.completed;
      case HotelStatus.cancelled:
        return AgendaEventStatus.cancelled;
    }
  }

  AgendaEventStatus _checkOutStatus(HotelStatus status) {
    switch (status) {
      case HotelStatus.requested:
      case HotelStatus.confirmed:
      case HotelStatus.checkedIn:
        return AgendaEventStatus.pending;
      case HotelStatus.checkedOut:
        return AgendaEventStatus.completed;
      case HotelStatus.cancelled:
        return AgendaEventStatus.cancelled;
    }
  }
}
