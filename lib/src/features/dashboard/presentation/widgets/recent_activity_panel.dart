import 'package:flutter/material.dart';
import '../../../agenda/domain/agenda_event.dart';
import '../../../hotels/domain/hotel_assignment.dart';
import '../../../tickets/domain/ticket.dart';
import '../../../transfers/domain/transfer.dart';
import '../../../workers/domain/worker.dart';

class RecentActivityPanel extends StatelessWidget {
  final List<Worker> workers;
  final List<Ticket> tickets;
  final List<HotelAssignment> hotels;
  final List<Transfer> transfers;
  final List<AgendaEvent> events;
  final VoidCallback onOpenAgenda;

  const RecentActivityPanel({
    super.key,
    required this.workers,
    required this.tickets,
    required this.hotels,
    required this.transfers,
    required this.events,
    required this.onOpenAgenda,
  });

  @override
  Widget build(BuildContext context) {
    final workerNames = {
      for (final worker in workers) worker.id: worker.fullName,
    };
    final activities = <_Activity>[];

    for (final ticket in tickets) {
      activities.add(
        _Activity(
          dateTime: _combine(ticket.travelDate, ticket.travelTime),
          title: ticket.status == TicketStatus.issued
              ? 'Pasaje emitido'
              : 'Pasaje ${ticket.status.label.toLowerCase()}',
          detail:
              '${workerNames[ticket.workerId] ?? 'Trabajador'} · ${ticket.company} ${ticket.serviceNumber}',
          icon: Icons.airplane_ticket_rounded,
          color: const Color(0xFFFF7A1A),
          status: ticket.status.label,
        ),
      );
    }

    for (final hotel in hotels) {
      activities.add(
        _Activity(
          dateTime: hotel.checkInDate,
          title: hotel.status == HotelStatus.checkedIn
              ? 'Check-in realizado'
              : 'Alojamiento ${hotel.status.label.toLowerCase()}',
          detail:
              '${workerNames[hotel.workerId] ?? 'Trabajador'} · ${hotel.hotelName}',
          icon: Icons.apartment_rounded,
          color: const Color(0xFF7B3FF2),
          status: hotel.status.label,
        ),
      );
    }

    for (final transfer in transfers) {
      activities.add(
        _Activity(
          dateTime: _combine(transfer.date, transfer.departureTime),
          title: transfer.status == TransferStatus.onRoute
              ? 'Traslado en ruta'
              : 'Traslado ${transfer.status.label.toLowerCase()}',
          detail:
              '${transfer.vehicleIdentifier} · ${transfer.origin} → ${transfer.destination}',
          icon: Icons.directions_bus_rounded,
          color: const Color(0xFF078AA5),
          status: transfer.status.label,
        ),
      );
    }

    for (final event in events) {
      if (activities.any(
        (item) => item.title == event.title && item.dateTime == event.dateTime,
      ))
        continue;
      activities.add(
        _Activity(
          dateTime: event.dateTime,
          title: event.title,
          detail: event.subtitle,
          icon: _eventIcon(event.type),
          color: const Color(0xFF2367F2),
          status: event.status.label,
        ),
      );
    }

    activities.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final visible = activities.take(6).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF2367F2)),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'ACTIVIDAD OPERACIONAL RECIENTE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: onOpenAgenda,
                child: const Text('Ver agenda'),
              ),
            ],
          ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Todavía no existen movimientos registrados.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ...visible.asMap().entries.map(
              (entry) => _ActivityTile(
                activity: entry.value,
                showDivider: entry.key != visible.length - 1,
              ),
            ),
        ],
      ),
    );
  }

  DateTime _combine(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  IconData _eventIcon(AgendaEventType type) {
    switch (type) {
      case AgendaEventType.ticket:
        return Icons.flight_takeoff_rounded;
      case AgendaEventType.hotelCheckIn:
        return Icons.login_rounded;
      case AgendaEventType.hotelCheckOut:
        return Icons.logout_rounded;
      case AgendaEventType.transfer:
        return Icons.directions_bus_rounded;
      case AgendaEventType.task:
        return Icons.task_alt_rounded;
    }
  }
}

class _ActivityTile extends StatelessWidget {
  final _Activity activity;
  final bool showDivider;

  const _ActivityTile({required this.activity, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final date =
        '${activity.dateTime.day.toString().padLeft(2, '0')}/${activity.dateTime.month.toString().padLeft(2, '0')}';
    final time =
        '${activity.dateTime.hour.toString().padLeft(2, '0')}:${activity.dateTime.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(activity.icon, color: activity.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activity.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: activity.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFEDF1F5)),
      ],
    );
  }
}

class _Activity {
  final DateTime dateTime;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final String status;

  const _Activity({
    required this.dateTime,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.status,
  });
}
