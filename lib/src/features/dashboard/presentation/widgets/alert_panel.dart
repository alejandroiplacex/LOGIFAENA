import 'package:flutter/material.dart';
import '../../../alerts/domain/operational_alert.dart';

class AlertPanel extends StatelessWidget {
  final List<OperationalAlert> alerts;
  final VoidCallback onViewAll;
  const AlertPanel({super.key, required this.alerts, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final critical = alerts
        .where((alert) => alert.severity == AlertSeverity.high)
        .length;
    final medium = alerts
        .where((alert) => alert.severity == AlertSeverity.medium)
        .length;
    final ticketAlerts = alerts
        .where((alert) => alert.category == AlertCategory.ticket)
        .length;
    final hotelAlerts = alerts
        .where((alert) => alert.category == AlertCategory.hotel)
        .length;
    final transferAlerts = alerts
        .where((alert) => alert.category == AlertCategory.transfer)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 10, 17, 14),
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
              const Icon(
                Icons.notification_important_rounded,
                color: Color(0xFFEF3340),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'CENTRO DE ALERTAS',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Ver todas')),
            ],
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'Críticas',
                    value: critical,
                    color: const Color(0xFFEF3340),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Atención',
                    value: medium,
                    color: const Color(0xFFF4A000),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Total',
                    value: alerts.length,
                    color: const Color(0xFF2367F2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _CategoryChip(
                  icon: Icons.airplane_ticket_rounded,
                  label: 'Pasajes',
                  value: ticketAlerts,
                ),
                _CategoryChip(
                  icon: Icons.apartment_rounded,
                  label: 'Hoteles',
                  value: hotelAlerts,
                ),
                _CategoryChip(
                  icon: Icons.directions_bus_rounded,
                  label: 'Traslados',
                  value: transferAlerts,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 44,
                    color: Color(0xFF16A36A),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No existen alertas pendientes',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else
            ...alerts.map((alert) => _AlertTile(alert: alert)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: color.withOpacity(.07),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: color.withOpacity(.16)),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF46617F)),
        const SizedBox(width: 5),
        Text(
          '$label $value',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF475569),
          ),
        ),
      ],
    ),
  );
}

class _AlertTile extends StatelessWidget {
  final OperationalAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert.severity == AlertSeverity.high
        ? const Color(0xFFEF3340)
        : alert.severity == AlertSeverity.medium
        ? const Color(0xFFF4A000)
        : const Color(0xFF2367F2);
    final label = alert.severity == AlertSeverity.high
        ? 'Crítica'
        : alert.severity == AlertSeverity.medium
        ? 'Media'
        : 'Baja';
    final icon = alert.category == AlertCategory.ticket
        ? Icons.airplane_ticket_rounded
        : alert.category == AlertCategory.hotel
        ? Icons.apartment_rounded
        : Icons.directions_bus_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5EAF1)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}
