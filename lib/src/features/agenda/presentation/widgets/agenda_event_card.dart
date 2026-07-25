import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workers/domain/worker.dart';
import '../../domain/agenda_event.dart';

class AgendaEventCard extends StatelessWidget {
  final AgendaEvent event;
  final Worker? worker;

  const AgendaEventCard({
    super.key,
    required this.event,
    required this.worker,
  });

  Color get typeColor {
    switch (event.type) {
      case AgendaEventType.ticket:
        return Colors.deepOrange;
      case AgendaEventType.hotelCheckIn:
        return Colors.blue;
      case AgendaEventType.hotelCheckOut:
        return Colors.indigo;
      case AgendaEventType.transfer:
        return Colors.amber.shade800;
      case AgendaEventType.task:
        return Colors.purple;
    }
  }

  IconData get typeIcon {
    switch (event.type) {
      case AgendaEventType.ticket:
        return Icons.flight_takeoff;
      case AgendaEventType.hotelCheckIn:
        return Icons.login;
      case AgendaEventType.hotelCheckOut:
        return Icons.logout;
      case AgendaEventType.transfer:
        return Icons.directions_bus;
      case AgendaEventType.task:
        return Icons.task_alt;
    }
  }

  Color get statusColor {
    switch (event.status) {
      case AgendaEventStatus.pending:
        return AppColors.warning;
      case AgendaEventStatus.confirmed:
        return AppColors.success;
      case AgendaEventStatus.completed:
        return Colors.blueGrey;
      case AgendaEventStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    event.time,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(typeIcon, color: typeColor),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker?.fullName ?? 'Trabajador no encontrado',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.subtitle} · ${event.location}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              avatar: CircleAvatar(
                radius: 5,
                backgroundColor: statusColor,
              ),
              label: Text(event.status.label),
              backgroundColor: statusColor.withOpacity(0.10),
              side: BorderSide(color: statusColor.withOpacity(0.35)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
