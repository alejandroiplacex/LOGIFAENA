import 'package:flutter/material.dart';
import '../data/operational_alert_service.dart';
import '../domain/operational_alert.dart';

class AlertsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  final ValueChanged<String>? onManageTicket;
  final ValueChanged<String>? onManageTransfer;
  final ValueChanged<String>? onManageHotel;

  const AlertsScreen({
    super.key,
    this.onNavigate,
    this.onManageTicket,
    this.onManageHotel,
    this.onManageTransfer,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertCategory? _category;

  @override
  Widget build(BuildContext context) {
    final allAlerts = OperationalAlertService.instance.getAlerts();
    final alerts = _category == null
        ? allAlerts
        : allAlerts.where((alert) => alert.category == _category).toList();

    return ColoredBox(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _TitleBlock(),
                _SummaryBadge(
                  label: 'Críticas',
                  value: allAlerts
                      .where((alert) => alert.severity == AlertSeverity.high)
                      .length,
                  icon: Icons.error_rounded,
                  color: const Color(0xFFDC2626),
                ),
                _SummaryBadge(
                  label: 'Medias',
                  value: allAlerts
                      .where((alert) => alert.severity == AlertSeverity.medium)
                      .length,
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFD97706),
                ),
                _SummaryBadge(
                  label: 'Total',
                  value: allAlerts.length,
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFF2367F2),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _FilterBar(
              selected: _category,
              onSelected: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 18),
            if (alerts.isEmpty)
              const _EmptyState()
            else
              ...alerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AlertCard(
                    alert: alert,
                    onAction:
                        alert.category == AlertCategory.ticket &&
                            widget.onManageTicket != null
                        ? () => widget.onManageTicket!(alert.workerId)
                        : alert.category == AlertCategory.hotel &&
                              widget.onManageHotel != null
                        ? () => widget.onManageHotel!(alert.workerId)
                        : alert.category == AlertCategory.transfer &&
                              widget.onManageTransfer != null
                        ? () => widget.onManageTransfer!(alert.workerId)
                        : widget.onNavigate == null
                        ? null
                        : () =>
                              widget.onNavigate!(_moduleIndex(alert.category)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _moduleIndex(AlertCategory category) {
    switch (category) {
      case AlertCategory.presentation:
        return 1;
      case AlertCategory.ticket:
        return 3;
      case AlertCategory.hotel:
        return 4;
      case AlertCategory.transfer:
        return 5;
    }
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 330,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas operacionales',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 5),
          Text(
            'Pendientes detectados automáticamente en pasajes, hoteles y traslados.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final AlertCategory? selected;
  final ValueChanged<AlertCategory?> onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),

        ChoiceChip(
          label: const Text('Presentación'),
          selected: selected == AlertCategory.presentation,
          onSelected: (_) => onSelected(AlertCategory.presentation),
        ),

        ChoiceChip(
          label: const Text('Pasajes'),
          selected: selected == AlertCategory.ticket,
          onSelected: (_) => onSelected(AlertCategory.ticket),
        ),
        ChoiceChip(
          label: const Text('Hoteles'),
          selected: selected == AlertCategory.hotel,
          onSelected: (_) => onSelected(AlertCategory.hotel),
        ),
        ChoiceChip(
          label: const Text('Traslados'),
          selected: selected == AlertCategory.transfer,
          onSelected: (_) => onSelected(AlertCategory.transfer),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final OperationalAlert alert;
  final VoidCallback? onAction;

  const _AlertCard({required this.alert, this.onAction});

  @override
  Widget build(BuildContext context) {
    final color = alert.severity == AlertSeverity.high
        ? const Color(0xFFDC2626)
        : alert.severity == AlertSeverity.medium
        ? const Color(0xFFD97706)
        : const Color(0xFF2367F2);
    final categoryLabel = switch (alert.category) {
      AlertCategory.presentation => 'Presentación',
      AlertCategory.ticket => 'Pasaje',
      AlertCategory.hotel => 'Hotel',
      AlertCategory.transfer => 'Traslado',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.warning_rounded, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _Tag(label: categoryLabel, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.detail,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trabajador: ${alert.workerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Gestionar'),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 58, color: Color(0xFF16A36A)),
          SizedBox(height: 12),
          Text(
            'No hay alertas en esta categoría',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 5),
          Text(
            'La operación se encuentra cubierta.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
