import 'package:flutter/material.dart';

import '../data/worker_repository.dart';
import '../domain/worker.dart';

class PresentationControlScreen extends StatefulWidget {
  const PresentationControlScreen({super.key});

  @override
  State<PresentationControlScreen> createState() =>
      _PresentationControlScreenState();
}

class _PresentationControlScreenState extends State<PresentationControlScreen> {
  final repository = InMemoryWorkerRepository.instance;
  final searchController = TextEditingController();

  PresentationStatus? selectedStatus;

  List<Worker> get workers {
    final query = searchController.text.trim().toLowerCase();

    return repository.getAll().where((worker) {
      final matchesSearch =
          query.isEmpty ||
          worker.fullName.toLowerCase().contains(query) ||
          worker.rut.toLowerCase().contains(query) ||
          worker.role.toLowerCase().contains(query);

      final matchesStatus =
          selectedStatus == null || worker.presentationStatus == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int count(PresentationStatus status) {
    return repository
        .getAll()
        .where((worker) => worker.presentationStatus == status)
        .length;
  }

  void setPresentationStatus(Worker worker, PresentationStatus status) {
    setState(() {
      worker.presentationStatus = status;

      if (status == PresentationStatus.pending) {
        worker.presentationAt = null;
      } else {
        worker.presentationAt = DateTime.now();
      }

      repository.update(worker);
    });
  }

  Color statusColor(PresentationStatus status) {
    switch (status) {
      case PresentationStatus.pending:
        return const Color(0xFFD97706);

      case PresentationStatus.presented:
        return const Color(0xFF16A36A);

      case PresentationStatus.late:
        return const Color(0xFF2563EB);

      case PresentationStatus.absent:
        return const Color(0xFFDC2626);
    }
  }

  IconData statusIcon(PresentationStatus status) {
    switch (status) {
      case PresentationStatus.pending:
        return Icons.schedule_rounded;

      case PresentationStatus.presented:
        return Icons.check_circle_rounded;

      case PresentationStatus.late:
        return Icons.access_time_rounded;

      case PresentationStatus.absent:
        return Icons.person_off_rounded;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = repository.getAll();
    final filtered = workers;

    return Scaffold(
      appBar: AppBar(title: const Text('Control de presentación')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard(
                  'Esperados',
                  all.length,
                  Icons.groups_rounded,
                  const Color(0xFF475569),
                ),
                _summaryCard(
                  'Pendientes',
                  count(PresentationStatus.pending),
                  Icons.schedule_rounded,
                  const Color(0xFFD97706),
                ),
                _summaryCard(
                  'Presentados',
                  count(PresentationStatus.presented),
                  Icons.check_circle_rounded,
                  const Color(0xFF16A36A),
                ),
                _summaryCard(
                  'Tardíos',
                  count(PresentationStatus.late),
                  Icons.access_time_rounded,
                  const Color(0xFF2563EB),
                ),
                _summaryCard(
                  'No se presentaron',
                  count(PresentationStatus.absent),
                  Icons.person_off_rounded,
                  const Color(0xFFDC2626),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Buscar trabajador o RUT',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<PresentationStatus?>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem<PresentationStatus?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...PresentationStatus.values.map(
                        (status) => DropdownMenuItem<PresentationStatus?>(
                          value: status,
                          child: Text(status.label),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedStatus = value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No se encontraron trabajadores.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final worker = filtered[index];
                        final status = worker.presentationStatus;
                        final color = statusColor(status);

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: color.withValues(alpha: .12),
                                  child: Icon(statusIcon(status), color: color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        worker.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${worker.rut} · '
                                        '${worker.role} · '
                                        '${worker.project}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        status.label,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _statusButton(
                                      worker,
                                      PresentationStatus.presented,
                                      'Presentado',
                                    ),
                                    _statusButton(
                                      worker,
                                      PresentationStatus.late,
                                      'Tardío',
                                    ),
                                    _statusButton(
                                      worker,
                                      PresentationStatus.absent,
                                      'No se presentó',
                                    ),
                                    IconButton(
                                      tooltip: 'Volver a pendiente',
                                      onPressed: () => setPresentationStatus(
                                        worker,
                                        PresentationStatus.pending,
                                      ),
                                      icon: const Icon(
                                        Icons.restart_alt_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, int value, IconData icon, Color color) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton(Worker worker, PresentationStatus status, String label) {
    final selected = worker.presentationStatus == status;
    final color = statusColor(status);

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      avatar: Icon(
        statusIcon(status),
        size: 17,
        color: selected ? Colors.white : color,
      ),
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) {
        setPresentationStatus(worker, status);
      },
    );
  }
}
