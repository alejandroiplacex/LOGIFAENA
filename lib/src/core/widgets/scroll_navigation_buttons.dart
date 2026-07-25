import 'package:flutter/material.dart';

/// Controles visibles para desplazar contenidos largos en escritorio y web.
class ScrollNavigationButtons extends StatelessWidget {
  final ScrollController controller;
  final double step;

  const ScrollNavigationButtons({
    super.key,
    required this.controller,
    this.step = 420,
  });

  Future<void> _move(double delta) async {
    if (!controller.hasClients) return;
    final position = controller.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: 18,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Subir',
              onPressed: () => _move(-step),
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            const SizedBox(width: 34, child: Divider(height: 1)),
            IconButton(
              tooltip: 'Bajar',
              onPressed: () => _move(step),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
