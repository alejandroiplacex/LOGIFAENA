import 'package:flutter/material.dart';

class ModulePlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 74, color: Colors.black38),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  const Chip(label: Text('Preparado para el siguiente sprint')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
