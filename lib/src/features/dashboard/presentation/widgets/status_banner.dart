import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  final int alertCount;
  final int activeWorkers;
  final int arrivalsToday;
  const StatusBanner({
    super.key,
    required this.alertCount,
    required this.activeWorkers,
    required this.arrivalsToday,
  });

  @override
  Widget build(BuildContext context) {
    final critical = alertCount >= 50;
    final highRisk = alertCount >= 20 && alertCount < 50;
    final attention = alertCount > 0 && alertCount < 20;
    final color = critical
        ? const Color(0xFFDC2626)
        : highRisk
        ? const Color(0xFFEA580C)
        : attention
        ? const Color(0xFFD97706)
        : const Color(0xFF159A59);
    final title = critical
        ? 'OPERACIÓN CRÍTICA'
        : highRisk
        ? 'OPERACIÓN EN RIESGO ALTO'
        : attention
        ? 'OPERACIÓN BAJO OBSERVACIÓN'
        : 'OPERACIÓN NORMAL';
    final icon = critical
        ? Icons.priority_high_rounded
        : (highRisk || attention)
        ? Icons.warning_amber_rounded
        : Icons.check_rounded;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .12), Colors.white],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$activeWorkers trabajadores activos  •  $arrivalsToday llegadas hoy  •  ${alertCount == 0 ? 'Sin incidencias críticas' : '$alertCount alertas pendientes'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.landscape_rounded,
            size: 64,
            color: Color(0xFFB8D5E8),
          ),
        ],
      ),
    );
  }
}
