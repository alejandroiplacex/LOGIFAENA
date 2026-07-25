import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final DateTime now;
  final int alertCount;
  const DashboardHeader({super.key, required this.now, required this.alertCount});

  @override
  Widget build(BuildContext context) {
    final date = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Centro de Operaciones Ejecutivo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10233F))),
          SizedBox(height: 4),
          Text('Control integral de la operación logística', style: TextStyle(color: Color(0xFF64748B))),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _InfoChip(icon: Icons.calendar_today_rounded, label: date),
          const SizedBox(width: 10),
          _InfoChip(icon: Icons.access_time_rounded, label: time),
          const SizedBox(width: 10),
          Badge(isLabelVisible: alertCount > 0, label: Text('$alertCount'), child: IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded))),
        ]),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: const Color(0xFF46617F)), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]),
  );
}
