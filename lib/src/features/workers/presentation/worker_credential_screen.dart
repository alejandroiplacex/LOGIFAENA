import 'package:flutter/material.dart';

import '../domain/worker.dart';
import 'widgets/worker_credential_card.dart';


class WorkerCredentialScreen extends StatelessWidget {
  final Worker worker;

  const WorkerCredentialScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Credencial del trabajador'),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          primary: true,
          padding: const EdgeInsets.all(24),
          child: Center(child: WorkerCredentialCard(worker: worker)),
        ),
      ),
    );
  }
}
