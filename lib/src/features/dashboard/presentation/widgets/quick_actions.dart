import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const QuickActions({super.key, required this.onNavigate});
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        'Nuevo trabajador',
        Icons.person_add_alt_1_rounded,
        const Color(0xFF2367F2),
        1,
      ),
      ('Emitir pasaje', Icons.flight_rounded, const Color(0xFF16A36A), 3),
      ('Asignar hotel', Icons.apartment_rounded, const Color(0xFF7B3FF2), 4),
      (
        'Programar traslado',
        Icons.directions_bus_rounded,
        const Color(0xFF078AA5),
        5,
      ),
      (
        'Abrir agenda',
        Icons.calendar_month_rounded,
        const Color(0xFFFF7A1A),
        2,
      ),
      ('Ver reportes', Icons.bar_chart_rounded, const Color(0xFF0B3A6E), 6),
    ];
    return Container(
      padding: const EdgeInsets.all(17),
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
          const Text(
            'ACCIONES RÁPIDAS',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 470 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.75,
                ),
                itemBuilder: (_, i) {
                  final a = actions[i];
                  return OutlinedButton.icon(
                    onPressed: () => onNavigate(a.$4),
                    icon: Icon(a.$2, color: a.$3),
                    label: Text(a.$1, textAlign: TextAlign.center),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF172033),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
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
