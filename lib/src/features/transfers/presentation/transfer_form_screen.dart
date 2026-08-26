import 'package:flutter/material.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../domain/transfer.dart';
import '../data/transfer_repository.dart';

class TransferFormScreen extends StatefulWidget {
  final Transfer? transfer;
  final String? initialWorkerId;

  const TransferFormScreen({super.key, this.transfer, this.initialWorkerId});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final formKey = GlobalKey<FormState>();
  final workersRepository = InMemoryWorkerRepository.instance;
  final transferRepository = InMemoryTransferRepository.instance;
  late DateTime date;
  late TransferVehicleType vehicleType;
  late TransferPurpose purpose;
  late TransferStatus status;
  late Set<String> selectedWorkerIds;

  late final TextEditingController code;
  late final TextEditingController departureTime;
  late final TextEditingController estimatedArrivalTime;
  late final TextEditingController origin;
  late final TextEditingController destination;
  late final TextEditingController routeDescription;
  late final TextEditingController vehicleIdentifier;
  late final TextEditingController licensePlate;
  late final TextEditingController capacity;
  late final TextEditingController driverName;
  late final TextEditingController driverPhone;
  late final TextEditingController providerCompany;
  late final TextEditingController notes;

  bool get editing => widget.transfer != null;
  Set<String> get workerIdsAssignedToOtherTransfersInSameGroup {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    final serviceGroupId = switch (purpose) {
      TransferPurpose.dailyOutbound => 'DAILY-$dateKey-OUTBOUND',
      TransferPurpose.dailyReturn => 'DAILY-$dateKey-RETURN',
      _ => '',
    };

    if (serviceGroupId.isEmpty) {
      return <String>{};
    }

    final currentTransferId = widget.transfer?.id;

    return transferRepository
        .findByServiceGroupId(serviceGroupId)
        .where((transfer) => transfer.id != currentTransferId)
        .expand((transfer) => transfer.workerIds)
        .toSet();
  }

  List<Worker> get workers {
    final allWorkers = workersRepository.getAll();

    return allWorkers.where((worker) {
      if (workerIdsAssignedToOtherTransfersInSameGroup.contains(worker.id)) {
        return false;
      }
      // Si ya está seleccionado, siempre debe seguir visible.
      if (selectedWorkerIds.contains(worker.id)) {
        return true;
      }

      switch (purpose) {
        case TransferPurpose.dailyOutbound:
          // Ida diaria: mostrar trabajadores que están en el hotel.
          return worker.operationalLocation == WorkerOperationalLocation.hotel;

        case TransferPurpose.dailyReturn:
          // Retorno diario: mostrar trabajadores que están en faena.
          return worker.operationalLocation == WorkerOperationalLocation.site;

        case TransferPurpose.turnArrival:
        case TransferPurpose.turnDeparture:
        case TransferPurpose.special:
          // Para los demás tipos mantenemos todos disponibles.
          return true;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    final transfer = widget.transfer;

    date = transfer?.date ?? DateTime.now();
    vehicleType = transfer?.vehicleType ?? TransferVehicleType.bus;
    purpose = transfer?.purpose ?? TransferPurpose.special;
    status = transfer?.status ?? TransferStatus.scheduled;
    selectedWorkerIds = {
      ...?transfer?.workerIds,
      if (transfer == null && widget.initialWorkerId != null)
        widget.initialWorkerId!,
    };

    code = TextEditingController(
      text:
          transfer?.code ??
          'TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    departureTime = TextEditingController(text: transfer?.departureTime ?? '');
    estimatedArrivalTime = TextEditingController(
      text: transfer?.estimatedArrivalTime ?? '',
    );
    origin = TextEditingController(text: transfer?.origin ?? '');
    destination = TextEditingController(text: transfer?.destination ?? '');
    routeDescription = TextEditingController(
      text: transfer?.routeDescription ?? '',
    );
    vehicleIdentifier = TextEditingController(
      text: transfer?.vehicleIdentifier ?? '',
    );
    licensePlate = TextEditingController(text: transfer?.licensePlate ?? '');
    capacity = TextEditingController(
      text: transfer == null ? '10' : transfer.capacity.toString(),
    );
    driverName = TextEditingController(text: transfer?.driverName ?? '');
    driverPhone = TextEditingController(text: transfer?.driverPhone ?? '');
    providerCompany = TextEditingController(
      text: transfer?.providerCompany ?? '',
    );
    notes = TextEditingController(text: transfer?.notes ?? '');
  }

  @override
  void dispose() {
    code.dispose();
    departureTime.dispose();
    estimatedArrivalTime.dispose();
    origin.dispose();
    destination.dispose();
    routeDescription.dispose();
    vehicleIdentifier.dispose();
    licensePlate.dispose();
    capacity.dispose();
    driverName.dispose();
    driverPhone.dispose();
    providerCompany.dispose();
    notes.dispose();
    super.dispose();
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: required ? requiredField : null,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() => date = selected);
    }
  }

  String formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void selectWorkersUpToCapacity() {
    final parsedCapacity = int.tryParse(capacity.text.trim()) ?? 0;

    if (parsedCapacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una capacidad válida para el vehículo.'),
        ),
      );
      return;
    }

    setState(() {
      selectedWorkerIds.clear();

      selectedWorkerIds.addAll(
        workers.take(parsedCapacity).map((worker) => worker.id),
      );
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final parsedCapacity = int.tryParse(capacity.text.trim()) ?? 0;

    if (selectedWorkerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un trabajador.')),
      );
      return;
    }

    if (parsedCapacity < selectedWorkerIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La capacidad debe ser al menos ${selectedWorkerIds.length}.',
          ),
        ),
      );
      return;
    }

    final dateKey =
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    final serviceGroupId = switch (purpose) {
      TransferPurpose.dailyOutbound => 'DAILY-$dateKey-OUTBOUND',
      TransferPurpose.dailyReturn => 'DAILY-$dateKey-RETURN',
      _ => '',
    };

    Navigator.pop(
      context,
      Transfer(
        id:
            widget.transfer?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        code: code.text.trim(),
        date: date,
        departureTime: departureTime.text.trim(),
        estimatedArrivalTime: estimatedArrivalTime.text.trim(),
        origin: origin.text.trim(),
        destination: destination.text.trim(),
        routeDescription: routeDescription.text.trim(),
        vehicleType: vehicleType,
        purpose: purpose,
        serviceGroupId: serviceGroupId,
        vehicleIdentifier: vehicleIdentifier.text.trim(),
        licensePlate: licensePlate.text.trim(),
        capacity: parsedCapacity,
        driverName: driverName.text.trim(),
        driverPhone: driverPhone.text.trim(),
        providerCompany: providerCompany.text.trim(),
        workerIds: selectedWorkerIds.toList(),
        notes: notes.text.trim(),
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar traslado' : 'Nuevo traslado'),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Programación',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formGrid([
                        field(code, 'Código', required: true),
                        InkWell(
                          onTap: pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(formatDate(date)),
                          ),
                        ),
                        field(departureTime, 'Hora de salida', required: true),
                        field(estimatedArrivalTime, 'Llegada estimada'),
                        field(origin, 'Origen', required: true),
                        field(destination, 'Destino', required: true),
                        field(routeDescription, 'Descripción de ruta'),
                        DropdownButtonFormField<TransferPurpose>(
                          initialValue: purpose,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de traslado',
                          ),
                          items: TransferPurpose.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => purpose = value);
                            }
                          },
                        ),
                        DropdownButtonFormField<TransferStatus>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: TransferStatus.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => status = value);
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Vehículo y conductor',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formGrid([
                        DropdownButtonFormField<TransferVehicleType>(
                          initialValue: vehicleType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de vehículo',
                          ),
                          items: TransferVehicleType.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => vehicleType = value);
                            }
                          },
                        ),
                        field(
                          vehicleIdentifier,
                          'Identificación del vehículo',
                          required: true,
                        ),
                        field(licensePlate, 'Patente', required: true),
                        field(
                          capacity,
                          'Capacidad',
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                        field(driverName, 'Conductor', required: true),
                        field(
                          driverPhone,
                          'Teléfono del conductor',
                          keyboardType: TextInputType.phone,
                        ),
                        field(providerCompany, 'Empresa transportista'),
                      ]),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Trabajadores asignados',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              '${selectedWorkerIds.length} seleccionado(s)',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Trabajadores disponibles: ${workers.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey,
                        ),
                      ),

                      if (workerIdsAssignedToOtherTransfersInSameGroup
                          .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${workerIdsAssignedToOtherTransfersInSameGroup.length} '
                            'trabajador(es) ya asignado(s) a otros buses de esta jornada',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: workers.isEmpty
                                ? null
                                : selectWorkersUpToCapacity,
                            icon: const Icon(
                              Icons.directions_bus_filled_rounded,
                            ),
                            label: const Text('Completar bus'),
                          ),
                          OutlinedButton.icon(
                            onPressed: selectedWorkerIds.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      selectedWorkerIds.clear();
                                    });
                                  },
                            icon: const Icon(Icons.clear_all_rounded),
                            label: const Text('Limpiar selección'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Card(
                        color: Colors.grey.shade50,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 330),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: workers.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final worker = workers[index];
                              final selected = selectedWorkerIds.contains(
                                worker.id,
                              );

                              return CheckboxListTile(
                                value: selected,
                                title: Text(worker.fullName),
                                subtitle: Text(
                                  '${worker.rut} · ${worker.project}',
                                ),
                                secondary: CircleAvatar(
                                  child: Text(
                                    worker.firstName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedWorkerIds.add(worker.id);
                                    } else {
                                      selectedWorkerIds.remove(worker.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notes,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: save,
                        icon: const Icon(Icons.save),
                        label: Text(
                          editing ? 'GUARDAR CAMBIOS' : 'CREAR TRASLADO',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
