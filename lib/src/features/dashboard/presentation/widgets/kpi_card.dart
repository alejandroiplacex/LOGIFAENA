import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const KpiCard({super.key, required this.title, required this.value, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(17),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE5EAF1)), boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 18, offset: Offset(0, 7))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)), const Spacer(), Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color)]),
        const Spacer(), Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
        const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 30, height: 1, fontWeight: FontWeight.w900, color: Color(0xFF172033))),
        const SizedBox(height: 7), Text(subtitle, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ]),
    )),
  );
}
