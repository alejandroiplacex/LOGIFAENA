import 'package:flutter/material.dart';

import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../data/transfer_repository.dart';
import '../domain/transfer.dart';

class TransferServiceGroupFormScreen extends StatefulWidget {
  const TransferServiceGroupFormScreen({super.key});

  @override
  State<TransferServiceGroupFormScreen> createState() =>
      _TransferServiceGroupFormScreenState();
}

class _TransferServiceGroupFormScreenState
    extends State<TransferServiceGroupFormScreen> {
  final workersRepository = InMemoryWorkerRepository.instance;
  final transferRepository = InMemoryTransferRepository.instance;

  final formKey = GlobalKey<FormState>();

  DateTime date = DateTime.now();
  TransferPurpose purpose = TransferPurpose.dailyOutbound;

  final origin = TextEditingController(text: 'Hotel Vitrali');
  final destination = TextEditingController(text: 'Manto Verde');
  final departureTime = TextEditingController(text: '05:35');
  final busCount = TextEditingController(text: '2');
  final busCapacity = TextEditingController(text: '42');

  List<Worker> get availableWorkers {
    final allWorkers = workersRepository.getAll();

    return allWorkers.where((worker) {
      switch (purpose) {
        case TransferPurpose.dailyOutbound:
          return worker.operationalLocation == WorkerOperationalLocation.hotel;

        case TransferPurpose.dailyReturn:
          return worker.operationalLocation == WorkerOperationalLocation.site;

        case TransferPurpose.turnArrival:
        case TransferPurpose.turnDeparture:
        case TransferPurpose.special:
          return false;
      }
    }).toList();
  }

  Map<WorkerOperationalLocation, int> get workerLocationCounts {
    final counts = <WorkerOperationalLocation, int>{};

    for (final location in WorkerOperationalLocation.values) {
      counts[location] = 0;
    }

    for (final worker in workersRepository.getAll()) {
      counts[worker.operationalLocation] =
          (counts[worker.operationalLocation] ?? 0) + 1;
    }

    return counts;
  }

  void initializeUnknownWorkersAtHotel() {
    final unknownWorkers = workersRepository
    .getAll()
    .where(
      (worker) =>
          worker.operationalLocation == WorkerOperationalLocation.unknown &&
          worker.presentationStatus != PresentationStatus.absent,
    )
    .toList();

    if (unknownWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay trabajadores sin ubicación.')),
      );
      return;
    }

    final now = DateTime.now();

    for (final worker in unknownWorkers) {
      worker.operationalLocation = WorkerOperationalLocation.hotel;
      worker.operationalLocationAt = now;
      workersRepository.update(worker);
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${unknownWorkers.length} trabajador(es) ubicados en Hotel Vitrali.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    departureTime.dispose();
    busCount.dispose();
    busCapacity.dispose();
    super.dispose();
  }

  String formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() {
        date = selected;
      });
    }
  }

  void applyPurposeDefaults(TransferPurpose value) {
    setState(() {
      purpose = value;

      switch (value) {
        case TransferPurpose.dailyOutbound:
          origin.text = 'Hotel Vitrali';
          destination.text = 'Manto Verde';
          departureTime.text = '05:35';
          break;

        case TransferPurpose.dailyReturn:
          origin.text = 'Manto Verde';
          destination.text = 'Hotel Vitrali';
          departureTime.text = '18:00';
          break;

        case TransferPurpose.turnArrival:
        case TransferPurpose.turnDeparture:
        case TransferPurpose.special:
          break;
      }
    });
  }

  void createServiceGroup({
    required List<Worker> workers,
    required List<int> distribution,
    required int capacity,
  }) {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    final serviceGroupId = switch (purpose) {
      TransferPurpose.dailyOutbound => 'DAILY-$dateKey-OUTBOUND',
      TransferPurpose.dailyReturn => 'DAILY-$dateKey-RETURN',
      _ => '',
    };

    var workerIndex = 0;

    for (var busIndex = 0; busIndex < distribution.length; busIndex++) {
      final assignedCount = distribution[busIndex];

      final assignedWorkers = workers
          .skip(workerIndex)
          .take(assignedCount)
          .map((worker) => worker.id)
          .toList();

      workerIndex += assignedCount;

      final busNumber = (busIndex + 1).toString().padLeft(2, '0');

      final transfer = Transfer(
        id: '${DateTime.now().microsecondsSinceEpoch}-$busNumber',
        code: 'TR-$dateKey-$busNumber',
        date: date,
        departureTime: departureTime.text.trim(),
        estimatedArrivalTime: '',
        origin: origin.text.trim(),
        destination: destination.text.trim(),
        routeDescription: '${origin.text.trim()} → ${destination.text.trim()}',
        vehicleType: TransferVehicleType.bus,
        purpose: purpose,
        serviceGroupId: serviceGroupId,
        vehicleIdentifier: 'BUS-$busNumber',
        licensePlate: '',
        capacity: capacity,
        driverName: '',
        driverPhone: '',
        providerCompany: '',
        workerIds: assignedWorkers,
        notes: '',
        status: TransferStatus.scheduled,
      );

      transferRepository.add(transfer);
    }
  }

  void calculateDistribution() {
    final buses = int.tryParse(busCount.text.trim()) ?? 0;
    final capacity = int.tryParse(busCapacity.text.trim()) ?? 0;
    final workers = availableWorkers;

    final dateKey =
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    final serviceGroupId = switch (purpose) {
      TransferPurpose.dailyOutbound => 'DAILY-$dateKey-OUTBOUND',
      TransferPurpose.dailyReturn => 'DAILY-$dateKey-RETURN',
      _ => '',
    };

    final existingGroup = transferRepository.findByServiceGroupId(
      serviceGroupId,
    );

    if (existingGroup.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ya existe una jornada para esta fecha y tipo '
            '(${existingGroup.length} bus(es) registrados).',
          ),
        ),
      );
      return;
    }

    if (buses <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida de buses.')),
      );
      return;
    }

    if (capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una capacidad válida por bus.')),
      );
      return;
    }

    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay trabajadores disponibles para esta jornada.'),
        ),
      );
      return;
    }

    final totalCapacity = buses * capacity;

    if (workers.length > totalCapacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No hay capacidad suficiente. '
            '${workers.length} trabajadores requieren '
            'al menos ${(workers.length / capacity).ceil()} buses.',
          ),
        ),
      );
      return;
    }

    final base = workers.length ~/ buses;
    final remainder = workers.length % buses;

    final distribution = <int>[];

    for (var index = 0; index < buses; index++) {
      final assigned = base + (index < remainder ? 1 : 0);
      distribution.add(assigned);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Distribución sugerida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${workers.length} trabajadores disponibles'),
              const SizedBox(height: 12),
              ...List.generate(
                distribution.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'BUS-${(index + 1).toString().padLeft(2, '0')}: '
                    '${distribution[index]} trabajadores',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                createServiceGroup(
                  workers: workers,
                  distribution: distribution,
                  capacity: capacity,
                );

                Navigator.pop(context);
              },
              icon: const Icon(Icons.add_road_rounded),
              label: const Text('Crear jornada'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = workerLocationCounts;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva jornada')),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Configuración de jornada',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 18),

                          InkWell(
                            onTap: pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              child: Text(formatDate(date)),
                            ),
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<TransferPurpose>(
                            initialValue: purpose,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de jornada',
                              prefixIcon: Icon(Icons.alt_route_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: TransferPurpose.dailyOutbound,
                                child: Text('Ida diaria a faena'),
                              ),
                              DropdownMenuItem(
                                value: TransferPurpose.dailyReturn,
                                child: Text('Retorno diario a hotel'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                applyPurposeDefaults(value);
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: origin,
                            decoration: const InputDecoration(
                              labelText: 'Origen',
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: destination,
                            decoration: const InputDecoration(
                              labelText: 'Destino',
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: departureTime,
                            decoration: const InputDecoration(
                              labelText: 'Hora de salida',
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: busCount,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad de buses',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: busCapacity,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Capacidad por bus',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnóstico de ubicación',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Hotel: '
                            '${counts[WorkerOperationalLocation.hotel] ?? 0}',
                          ),

                          Text(
                            'Faena: '
                            '${counts[WorkerOperationalLocation.site] ?? 0}',
                          ),

                          Text(
                            'En traslado a faena: '
                            '${counts[WorkerOperationalLocation.travelingToSite] ?? 0}',
                          ),

                          Text(
                            'En retorno al hotel: '
                            '${counts[WorkerOperationalLocation.returningToHotel] ?? 0}',
                          ),

                          Text(
                            'Sin ubicación: '
                            '${counts[WorkerOperationalLocation.unknown] ?? 0}',
                          ),

                          const SizedBox(height: 12),

                          OutlinedButton.icon(
                            onPressed:
                                (counts[WorkerOperationalLocation.unknown] ??
                                        0) >
                                    0
                                ? initializeUnknownWorkersAtHotel
                                : null,
                            icon: const Icon(Icons.hotel_rounded),
                            label: const Text(
                              'Inicializar sin ubicación en hotel',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  FilledButton.icon(
                    onPressed: calculateDistribution,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Calcular distribución'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
