import 'package:flutter/material.dart';
import '../../../workers/domain/worker.dart';

class WorkerStatusOverview extends StatelessWidget {
  final List<Worker> workers;
  final VoidCallback onOpenWorkers;
  final ValueChanged<WorkerStatus> onStatusSelected;

  const WorkerStatusOverview({
    super.key,
    required this.workers,
    required this.onOpenWorkers,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_StatusItem>[
      _StatusItem('Pendientes', WorkerStatus.pending, Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
      _StatusItem('Pasaje emitido', WorkerStatus.ticketIssued, Icons.airplane_ticket_rounded, const Color(0xFF2563EB)),
      _StatusItem('En viaje', WorkerStatus.traveling, Icons.flight_takeoff_rounded, const Color(0xFF7C3AED)),
      _StatusItem('Alojados', WorkerStatus.lodging, Icons.hotel_rounded, const Color(0xFF9333EA)),
      _StatusItem('En traslado', WorkerStatus.transfer, Icons.directions_bus_rounded, const Color(0xFF0891B2)),
      _StatusItem('En faena', WorkerStatus.atSite, Icons.engineering_rounded, const Color(0xFF16A34A)),
    ];

    final totalOperational = workers
        .where((w) => w.status != WorkerStatus.finished && w.status != WorkerStatus.cancelled)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: Color(0xFF2367F2)),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'ESTADO OPERACIONAL DEL PERSONAL',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: onOpenWorkers,
                child: const Text('Ver personal'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$totalOperational trabajadores actualmente dentro del flujo logístico',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? 6
                  : constraints.maxWidth >= 480
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: columns == 6 ? 1.25 : 1.45,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final count = workers.where((w) => w.status == item.status).length;
                  final ratio = totalOperational == 0 ? 0.0 : count / totalOperational;
                  return _StatusTile(
                    item: item,
                    count: count,
                    ratio: ratio,
                    onTap: () => onStatusSelected(item.status),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final _StatusItem item;
  final int count;
  final double ratio;
  final VoidCallback onTap;

  const _StatusTile({
    required this.item,
    required this.count,
    required this.ratio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.color.withOpacity(.055),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.color.withOpacity(.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF172033),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  color: item.color,
                  backgroundColor: item.color.withOpacity(.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem {
  final String label;
  final WorkerStatus status;
  final IconData icon;
  final Color color;

  const _StatusItem(this.label, this.status, this.icon, this.color);
}
