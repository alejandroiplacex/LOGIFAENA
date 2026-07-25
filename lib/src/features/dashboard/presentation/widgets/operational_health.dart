import 'dart:math' as math;
import 'package:flutter/material.dart';

class OperationalHealth extends StatelessWidget {
  final int value, alertCount;
  const OperationalHealth({super.key, required this.value, required this.alertCount});
  @override
  Widget build(BuildContext context) {
    final color = value >= 85 ? const Color(0xFF16A36A) : value >= 65 ? const Color(0xFFF4A000) : const Color(0xFFEF3340);
    final label = value >= 85 ? 'Excelente' : value >= 65 ? 'Requiere atención' : 'Crítica';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE5EAF1)), boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 18, offset: Offset(0, 7))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SALUD OPERACIONAL', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 14),
        Row(children: [
          SizedBox(width: 120, height: 120, child: CustomPaint(painter: _RingPainter(progress: value / 100, color: color), child: Center(child: Text('$value%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))))),
          const SizedBox(width: 22),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: color)), const SizedBox(height: 5), Text(alertCount == 0 ? 'Toda la operación está al día' : '$alertCount alertas requieren revisión'), const SizedBox(height: 14), LinearProgressIndicator(value: value / 100, minHeight: 8, borderRadius: BorderRadius.circular(10), color: color, backgroundColor: const Color(0xFFE8EDF3))]))
        ])
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 13..strokeCap = StrokeCap.round;
    paint.color = const Color(0xFFE8EDF3); canvas.drawArc(rect.deflate(9), -math.pi / 2, math.pi * 2, false, paint);
    paint.color = color; canvas.drawArc(rect.deflate(9), -math.pi / 2, math.pi * 2 * progress, false, paint);
  }
  @override bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
