import 'package:flutter/material.dart';

import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../data/transfer_repository.dart';
import '../domain/transfer.dart';
import '../../hotels/data/hotel_repository.dart';

class TransferPassengerControlScreen extends StatefulWidget {
  final Transfer transfer;

  const TransferPassengerControlScreen({super.key, required this.transfer});

  @override
  State<TransferPassengerControlScreen> createState() =>
      _TransferPassengerControlScreenState();
}

class _TransferPassengerControlScreenState
    extends State<TransferPassengerControlScreen> {
  final workerRepository = InMemoryWorkerRepository.instance;
  final hotelRepository = InMemoryHotelRepository.instance;
  final transferRepository = InMemoryTransferRepository.instance;

  Transfer get transfer => widget.transfer;

  Worker? _worker(String workerId) {
    for (final worker in workerRepository.getAll()) {
      if (worker.id == workerId) {
        return worker;
      }
    }
    return null;
  }

  void _changeStatus(String workerId, TransferPassengerStatus newStatus) {
    setState(() {
      transfer.setWorkerStatus(workerId, newStatus);

      final statuses = transfer.workerIds
          .map(transfer.statusForWorker)
          .toList();

      final allArrived =
          statuses.isNotEmpty &&
          statuses.every((status) => status == TransferPassengerStatus.arrived);

      final anyBoarded = statuses.any(
        (status) =>
            status == TransferPassengerStatus.boarded ||
            status == TransferPassengerStatus.arrived,
      );

      final allBoardedOrArrived =
          statuses.isNotEmpty &&
          statuses.every(
            (status) =>
                status == TransferPassengerStatus.boarded ||
                status == TransferPassengerStatus.arrived,
          );

      if (allArrived) {
        transfer.status = TransferStatus.completed;
      } else if (allBoardedOrArrived) {
        transfer.status = TransferStatus.onRoute;
      } else if (anyBoarded) {
        transfer.status = TransferStatus.boarding;
      } else {
        transfer.status = TransferStatus.scheduled;
      }
      final worker = _worker(workerId);

      if (worker != null) {
        switch (newStatus) {
          case TransferPassengerStatus.pending:
            break;

          case TransferPassengerStatus.boarded:
            worker.status = WorkerStatus.transfer;
            worker.operationalLocationAt = DateTime.now();

            switch (transfer.purpose) {
              case TransferPurpose.turnArrival:
                worker.operationalLocation =
                    WorkerOperationalLocation.travelingToCaldera;
                break;

              case TransferPurpose.dailyOutbound:
                worker.operationalLocation =
                    WorkerOperationalLocation.travelingToSite;
                break;

              case TransferPurpose.dailyReturn:
                worker.operationalLocation =
                    WorkerOperationalLocation.returningToHotel;
                break;

              case TransferPurpose.turnDeparture:
                worker.operationalLocation =
                    WorkerOperationalLocation.returningHome;
                break;

              case TransferPurpose.special:
                worker.operationalLocation = WorkerOperationalLocation.unknown;
                break;
            }

            workerRepository.update(worker);
            break;

          case TransferPassengerStatus.arrived:
            worker.operationalLocationAt = DateTime.now();

            switch (transfer.purpose) {
              case TransferPurpose.turnArrival:
                worker.status = WorkerStatus.lodging;
                worker.operationalLocation = WorkerOperationalLocation.hotel;
                break;

              case TransferPurpose.dailyOutbound:
                worker.status = WorkerStatus.atSite;
                worker.operationalLocation = WorkerOperationalLocation.site;
                break;

              case TransferPurpose.dailyReturn:
                worker.status = WorkerStatus.lodging;
                worker.operationalLocation = WorkerOperationalLocation.hotel;
                break;

              case TransferPurpose.turnDeparture:
                worker.status = WorkerStatus.finished;
                worker.operationalLocation =
                    WorkerOperationalLocation.returningHome;
                break;

              case TransferPurpose.special:
                worker.status = WorkerStatus.atSite;
                worker.operationalLocation = WorkerOperationalLocation.unknown;
                break;
            }

            workerRepository.update(worker);
            break;
        }
      }

      transferRepository.update(transfer);
    });
  }

  void _markAllBoarded() {
    for (final workerId in transfer.workerIds) {
      final currentStatus = transfer.statusForWorker(workerId);

      if (currentStatus == TransferPassengerStatus.pending) {
        _changeStatus(workerId, TransferPassengerStatus.boarded);
      }
    }
  }

  void _markAllArrived() {
    for (final workerId in transfer.workerIds) {
      final currentStatus = transfer.statusForWorker(workerId);

      if (currentStatus != TransferPassengerStatus.arrived) {
        _changeStatus(workerId, TransferPassengerStatus.arrived);
      }
    }
  }

  Color _statusColor(TransferPassengerStatus status) {
    switch (status) {
      case TransferPassengerStatus.pending:
        return const Color(0xFFD97706);
      case TransferPassengerStatus.boarded:
        return const Color(0xFF2563EB);
      case TransferPassengerStatus.arrived:
        return const Color(0xFF16A36A);
    }
  }

  IconData _statusIcon(TransferPassengerStatus status) {
    switch (status) {
      case TransferPassengerStatus.pending:
        return Icons.schedule_rounded;
      case TransferPassengerStatus.boarded:
        return Icons.directions_bus_rounded;
      case TransferPassengerStatus.arrived:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expected = transfer.expectedPassengers;
    final boarded = transfer.boardedPassengers;
    final arrived = transfer.arrivedPassengers;
    final pendingArrival = expected - arrived;

    return Scaffold(
      appBar: AppBar(title: const Text('Control de pasajeros')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_bus_rounded,
                              size: 32,
                              color: Color(0xFF0D477C),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transfer.code,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${transfer.origin} Ã¢â€ â€™ ${transfer.destination}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(label: Text(transfer.status.label)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${transfer.vehicleType.label} Ã‚Â· '
                          '${transfer.vehicleIdentifier} Ã‚Â· '
                          '${transfer.licensePlate} Ã‚Â· '
                          'Conductor: ${transfer.driverName}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 800
                        ? (constraints.maxWidth - 36) / 4
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _summaryCard(
                          width: cardWidth,
                          title: 'Esperados',
                          value: expected,
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF475569),
                        ),
                        _summaryCard(
                          width: cardWidth,
                          title: 'Abordaron',
                          value: boarded,
                          icon: Icons.directions_bus_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        _summaryCard(
                          width: cardWidth,
                          title: 'Llegaron',
                          value: arrived,
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF16A36A),
                        ),
                        _summaryCard(
                          width: cardWidth,
                          title: 'Por llegar',
                          value: pendingArrival,
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFD97706),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Trabajadores del traslado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Registra individualmente quiÃƒÂ©n abordÃƒÂ³ y quiÃƒÂ©n llegÃƒÂ³ al destino.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  transfer.workerIds.any(
                                    (workerId) =>
                                        transfer.statusForWorker(workerId) ==
                                        TransferPassengerStatus.pending,
                                  )
                                  ? _markAllBoarded
                                  : null,
                              icon: const Icon(Icons.directions_bus_rounded),
                              label: const Text('Todos abordaron'),
                            ),
                            FilledButton.icon(
                              onPressed:
                                  transfer.workerIds.any(
                                    (workerId) =>
                                        transfer.statusForWorker(workerId) !=
                                        TransferPassengerStatus.arrived,
                                  )
                                  ? _markAllArrived
                                  : null,
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                              label: const Text('Todos llegaron'),
                            ),
                          ],
                        ),

                        const Divider(height: 28),

                        if (transfer.workerIds.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(30),
                            child: Center(
                              child: Text(
                                'Este traslado no tiene trabajadores asignados.',
                              ),
                            ),
                          )
                        else
                          ...transfer.workerIds.map((workerId) {
                            final worker = _worker(workerId);
                            final passengerStatus = transfer.statusForWorker(
                              workerId,
                            );

                            return _workerRow(
                              workerId: workerId,
                              worker: worker,
                              status: passengerStatus,
                            );
                          }),
                      ],
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

  Widget _summaryCard({
    required double width,
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
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

  Widget _workerRow({
    required String workerId,
    required Worker? worker,
    required TransferPassengerStatus status,
  }) {
    final color = _statusColor(status);

    final fullName = worker?.fullName ?? 'Trabajador no encontrado';
    final rut = worker?.rut ?? 'Sin RUT';

    final hotelAssignment = hotelRepository.findByWorkerId(workerId);

    final hotel = hotelAssignment?.hotelName.trim().isNotEmpty == true
        ? hotelAssignment!.hotelName
        : 'Sin alojamiento';

    final room = hotelAssignment?.room.trim().isNotEmpty == true
        ? hotelAssignment!.room
        : 'Sin habitaciÃƒÂ³n';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final identity = Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(_statusIcon(status), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$rut Ã‚Â· $hotel Ã‚Â· HabitaciÃƒÂ³n: $room',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          );

          final availableStatuses = switch (status) {
            TransferPassengerStatus.pending => <TransferPassengerStatus>[
              TransferPassengerStatus.pending,
              TransferPassengerStatus.boarded,
            ],
            TransferPassengerStatus.boarded => <TransferPassengerStatus>[
              TransferPassengerStatus.boarded,
              TransferPassengerStatus.arrived,
            ],
            TransferPassengerStatus.arrived => <TransferPassengerStatus>[
              TransferPassengerStatus.arrived,
            ],
          };

          final controls = Wrap(
            spacing: 7,
            runSpacing: 7,
            children: availableStatuses.map((item) {
              final selected = status == item;
              final itemColor = _statusColor(item);

              return ChoiceChip(
                selected: selected,
                avatar: Icon(
                  _statusIcon(item),
                  size: 17,
                  color: selected ? Colors.white : itemColor,
                ),
                label: Text(item.label),
                onSelected: selected
                    ? null
                    : (_) {
                        _changeStatus(workerId, item);
                      },
                selectedColor: itemColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 12), controls],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 14),
              controls,
            ],
          );
        },
      ),
    );
  }
}
