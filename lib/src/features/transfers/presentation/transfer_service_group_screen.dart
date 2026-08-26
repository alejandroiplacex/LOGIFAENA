import 'package:flutter/material.dart';

import '../data/transfer_repository.dart';
import '../domain/transfer.dart';
import 'transfer_passenger_control_screen.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import 'transfer_form_screen.dart';

class TransferServiceGroupScreen extends StatefulWidget {
  final String serviceGroupId;

  const TransferServiceGroupScreen({super.key, required this.serviceGroupId});

  @override
  State<TransferServiceGroupScreen> createState() =>
      _TransferServiceGroupScreenState();
}

class _TransferServiceGroupScreenState
    extends State<TransferServiceGroupScreen> {
  final transferRepository = InMemoryTransferRepository.instance;
  final workerRepository = InMemoryWorkerRepository.instance;

  Worker? _worker(String workerId) {
    for (final worker in workerRepository.getAll()) {
      if (worker.id == workerId) {
        return worker;
      }
    }

    return null;
  }

  List<Transfer> get transfers =>
      transferRepository.findByServiceGroupId(widget.serviceGroupId);

  int get totalExpected => transfers.fold<int>(
    0,
    (sum, transfer) => sum + transfer.expectedPassengers,
  );

  int get totalBoarded => transfers.fold<int>(
    0,
    (sum, transfer) => sum + transfer.boardedPassengers,
  );

  int get totalArrived => transfers.fold<int>(
    0,
    (sum, transfer) => sum + transfer.arrivedPassengers,
  );

  int get totalPendingBoarding => totalExpected - totalBoarded;

  int get totalInTransit => totalBoarded - totalArrived;

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _openPassengerControl(Transfer transfer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferPassengerControlScreen(transfer: transfer),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editTransfer(Transfer transfer) async {
    final updated = await Navigator.push<Transfer>(
      context,
      MaterialPageRoute(builder: (_) => TransferFormScreen(transfer: transfer)),
    );

    if (!mounted || updated == null) {
      return;
    }

    transferRepository.update(updated);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final group = transfers;

    if (group.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Control de jornada')),
        body: const Center(
          child: Text('No se encontraron buses para esta jornada.'),
        ),
      );
    }

    final first = group.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Control de jornada')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${first.purpose.label} · ${_date(first.date)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${first.origin} → ${first.destination}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _metric(
                              icon: Icons.directions_bus_rounded,
                              label: 'Buses',
                              value: group.length,
                            ),
                            _metric(
                              icon: Icons.groups_rounded,
                              label: 'Esperados',
                              value: totalExpected,
                            ),
                            _metric(
                              icon: Icons.directions_bus_filled_rounded,
                              label: 'Abordaron',
                              value: totalBoarded,
                            ),
                            _metric(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Llegaron',
                              value: totalArrived,
                            ),
                            _metric(
                              icon: Icons.hourglass_bottom_rounded,
                              label: 'Por abordar',
                              value: totalPendingBoarding,
                            ),

                            _metric(
                              icon: Icons.route_rounded,
                              label: 'En viaje',
                              value: totalInTransit,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Buses de la jornada',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ...group.map(
                  (transfer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 27,
                              child: Icon(
                                transfer.vehicleType == TransferVehicleType.bus
                                    ? Icons.directions_bus_rounded
                                    : Icons.local_shipping_outlined,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${transfer.code} · '
                                    '${transfer.vehicleIdentifier}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${transfer.licensePlate} · '
                                    '${transfer.driverName}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${transfer.expectedPassengers} esperados · '
                                    '${transfer.expectedPassengers - transfer.boardedPassengers} por abordar · '
                                    '${transfer.boardedPassengers - transfer.arrivedPassengers} en viaje · '
                                    '${transfer.arrivedPassengers} llegaron',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  ...transfer.workerIds.map((workerId) {
                                    final worker = _worker(workerId);
                                    final passengerStatus = transfer
                                        .statusForWorker(workerId);

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 18,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              worker?.fullName ??
                                                  'Trabajador no encontrado',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Chip(
                                            label: Text(passengerStatus.label),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _editTransfer(transfer),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar bus'),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openPassengerControl(transfer),
                                  icon: const Icon(Icons.fact_check_outlined),
                                  label: const Text('Control pasajeros'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0D477C)),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
