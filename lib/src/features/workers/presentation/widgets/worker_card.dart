import 'package:flutter/material.dart';
import '../../domain/worker.dart';
import 'worker_status_chip.dart';
import '../../services/logistics_readiness_service.dart';

class WorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<WorkerStatus> onStatusChanged;

  const WorkerCard({
    super.key,
    required this.worker,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final readiness = LogisticsReadinessService.evaluate(worker);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 27,
                child: Text(
                  worker.firstName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('${worker.rut} · ${worker.company}'),
                    const SizedBox(height: 2),
                    Text(
                      '${worker.role} · ${worker.project} · ${worker.shift}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    _ReadinessIndicator(readiness: readiness),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              WorkerStatusChip(status: worker.status),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'Acciones rápidas',
                onSelected: (value) {
                  if (value == 'open') onOpen();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.visibility),
                      title: Text('Ver ficha'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.edit),
                      title: Text('Editar'),
                    ),
                  ),
                  PopupMenuItem(
                    enabled: false,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return DropdownButtonFormField<WorkerStatus>(
                          value: worker.status,
                          decoration: const InputDecoration(
                            labelText: 'Cambiar estado',
                            isDense: true,
                          ),
                          items: WorkerStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              onStatusChanged(value);
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessIndicator extends StatelessWidget {
  final LogisticsReadiness readiness;

  const _ReadinessIndicator({required this.readiness});

  @override
  Widget build(BuildContext context) {
    final color = switch (readiness.level) {
      LogisticsReadinessLevel.ready => const Color(0xFF15803D),
      LogisticsReadinessLevel.advanced => const Color(0xFF2563EB),
      LogisticsReadinessLevel.incomplete => const Color(0xFFD97706),
      LogisticsReadinessLevel.critical => const Color(0xFFDC2626),
    };
    return Wrap(
      spacing: 7,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(.09),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(.35)),
          ),
          child: Text(
            '${readiness.percentage}% · ${readiness.label}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _serviceIcon(Icons.airplane_ticket_outlined, readiness.hasTicket),
        _serviceIcon(Icons.hotel_outlined, readiness.hasHotel),
        _serviceIcon(Icons.directions_bus_outlined, readiness.hasTransfer),
      ],
    );
  }

  Widget _serviceIcon(IconData icon, bool completed) => Icon(
    completed ? Icons.check_circle : icon,
    size: 17,
    color: completed ? const Color(0xFF15803D) : Colors.black38,
  );
}
