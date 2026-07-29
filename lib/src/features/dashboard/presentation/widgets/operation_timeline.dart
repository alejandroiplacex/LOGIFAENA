import 'package:flutter/material.dart';
import '../../../agenda/domain/agenda_event.dart';

class OperationTimeline extends StatelessWidget {
  final List<AgendaEvent> events;
  final bool showingToday;
  final VoidCallback onOpenAgenda;
  const OperationTimeline({
    super.key,
    required this.events,
    required this.showingToday,
    required this.onOpenAgenda,
  });

  @override
  Widget build(BuildContext context) => _Panel(
    title: showingToday ? 'OPERACIÓN DEL DÍA' : 'PRÓXIMOS EVENTOS',
    action: TextButton(
      onPressed: onOpenAgenda,
      child: const Text('Ver agenda completa'),
    ),
    child: events.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: Text('No hay eventos programados.')),
          )
        : Column(children: events.map((e) => _EventRow(event: e)).toList()),
  );
}

class _EventRow extends StatelessWidget {
  final AgendaEvent event;
  const _EventRow({required this.event});
  @override
  Widget build(BuildContext context) {
    final data = _style(event.type);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDF1F6))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              event.time,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: data.$2.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.$1, color: data.$2, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.subtitle} · ${event.location}',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: data.$2.withOpacity(.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.status.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: data.$2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _style(AgendaEventType type) {
    switch (type) {
      case AgendaEventType.ticket:
        return (Icons.flight_rounded, const Color(0xFFFF7A1A));
      case AgendaEventType.hotelCheckIn:
      case AgendaEventType.hotelCheckOut:
        return (Icons.apartment_rounded, const Color(0xFF7B3FF2));
      case AgendaEventType.transfer:
        return (Icons.directions_bus_rounded, const Color(0xFF078AA5));
      case AgendaEventType.task:
        return (Icons.task_alt_rounded, const Color(0xFF2367F2));
    }
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;
  const _Panel({required this.title, this.action, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
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
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF2367F2)),
            const SizedBox(width: 9),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const Spacer(),
            if (action != null) action!,
          ],
        ),
        child,
      ],
    ),
  );
}
