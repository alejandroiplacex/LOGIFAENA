import '../../../core/database/database_service.dart';
import '../domain/ticket.dart';

abstract class TicketRepository {
  List<Ticket> getAll();
  Ticket? findByWorkerId(String workerId);
  void add(Ticket ticket);
  void replaceAll(List<Ticket> tickets);
  void update(Ticket ticket);
  void delete(String id);
}

class InMemoryTicketRepository implements TicketRepository {
  InMemoryTicketRepository._() {
    final saved = DatabaseService.instance.readList('logifaena_tickets');
    if (saved.isNotEmpty) {
      _tickets
        ..clear()
        ..addAll(saved.map(Ticket.fromJson));
    }
  }

  static final InMemoryTicketRepository instance = InMemoryTicketRepository._();

  final List<Ticket> _tickets = [
    Ticket(
      id: 't1',
      workerId: '1',
      type: TicketType.flight,
      company: 'LATAM',
      serviceNumber: 'LA345',
      bookingCode: 'HG45JK',
      origin: 'Santiago',
      destination: 'Calama',
      travelDate: DateTime(2026, 7, 20),
      travelTime: '08:15',
      baggage: '1 maleta de 23 kg',
      seat: '12A',
      notes: 'Pasaje confirmado.',
      status: TicketStatus.issued,
    ),
    Ticket(
      id: 't2',
      workerId: '2',
      type: TicketType.flight,
      company: 'SKY',
      serviceNumber: 'H201',
      bookingCode: 'SK1234',
      origin: 'Santiago',
      destination: 'Antofagasta',
      travelDate: DateTime(2026, 7, 22),
      travelTime: '10:40',
      baggage: 'Equipaje de cabina',
      seat: '',
      notes: 'Pendiente confirmar asiento.',
      status: TicketStatus.requested,
    ),
  ];

  void _persist() {
    DatabaseService.instance.writeList(
      'logifaena_tickets',
      _tickets.map((item) => item.toJson()).toList(),
    );
  }

  @override
  List<Ticket> getAll() => List.unmodifiable(_tickets);

  @override
  Ticket? findByWorkerId(String workerId) {
    for (final ticket in _tickets) {
      if (ticket.workerId == workerId) return ticket;
    }
    return null;
  }

  @override
  void add(Ticket ticket) {
    _tickets.add(ticket);
    _persist();
  }

  @override
  void replaceAll(List<Ticket> tickets) {
    _tickets
      ..clear()
      ..addAll(tickets);
    _persist();
  }

  @override
  void update(Ticket ticket) {
    final index = _tickets.indexWhere((item) => item.id == ticket.id);
    if (index != -1) {
      _tickets[index] = ticket;
      _persist();
    }
  }

  @override
  void delete(String id) {
    _tickets.removeWhere((ticket) => ticket.id == id);
    _persist();
  }
}
