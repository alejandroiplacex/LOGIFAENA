import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../data/transfer_repository.dart';
import '../domain/transfer.dart';
import 'transfer_form_screen.dart';
import 'transfer_passenger_control_screen.dart';
import 'transfer_service_group_form_screen.dart';
import 'transfer_service_group_screen.dart';
import 'widgets/transfer_status_chip.dart';

class TransfersScreen extends StatefulWidget {
  final String? initialWorkerId;

  const TransfersScreen({super.key, this.initialWorkerId});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  final transferRepository = InMemoryTransferRepository.instance;
  final workerRepository = InMemoryWorkerRepository.instance;
  final searchController = TextEditingController();

  TransferStatus? selectedStatus;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final initialWorkerId = widget.initialWorkerId;

      if (initialWorkerId != null && initialWorkerId.trim().isNotEmpty) {
        final existingTransfers = transferRepository.findByWorkerId(
          initialWorkerId,
        );

        final activeTransfers = existingTransfers
            .where((transfer) => transfer.status != TransferStatus.cancelled)
            .toList();

        if (activeTransfers.isNotEmpty) {
          await editTransfer(activeTransfers.first);
        } else {
          await addTransfer();
        }
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Map<String, List<Transfer>> get serviceGroups {
    final groups = <String, List<Transfer>>{};

    for (final transfer in transferRepository.getAll()) {
      final groupId = transfer.serviceGroupId.trim();

      if (groupId.isEmpty) {
        continue;
      }

      groups.putIfAbsent(groupId, () => <Transfer>[]).add(transfer);
    }

    return groups;
  }

  ({int buses, int expected, int boarded, int arrived, int pending})
  _serviceGroupTotals(List<Transfer> group) {
    final buses = group.length;

    final expected = group.fold<int>(
      0,
      (sum, transfer) => sum + transfer.expectedPassengers,
    );

    final boarded = group.fold<int>(
      0,
      (sum, transfer) => sum + transfer.boardedPassengers,
    );

    final arrived = group.fold<int>(
      0,
      (sum, transfer) => sum + transfer.arrivedPassengers,
    );

    final pending = expected - arrived;

    return (
      buses: buses,
      expected: expected,
      boarded: boarded,
      arrived: arrived,
      pending: pending,
    );
  }

  List<Transfer> get transfers {
    final query = searchController.text.trim().toLowerCase();

    return transferRepository.getAll().where((transfer) {
      final workerNames = transfer.workerIds
          .map(_worker)
          .whereType<Worker>()
          .map((worker) => worker.fullName.toLowerCase())
          .join(' ');

      final matchesSearch =
          query.isEmpty ||
          workerNames.contains(query) ||
          transfer.code.toLowerCase().contains(query) ||
          transfer.origin.toLowerCase().contains(query) ||
          transfer.destination.toLowerCase().contains(query) ||
          transfer.vehicleIdentifier.toLowerCase().contains(query) ||
          transfer.licensePlate.toLowerCase().contains(query) ||
          transfer.driverName.toLowerCase().contains(query) ||
          transfer.providerCompany.toLowerCase().contains(query);

      final matchesStatus =
          selectedStatus == null || transfer.status == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList()..sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.departureTime.compareTo(b.departureTime);
    });
  }

  Worker? _worker(String id) {
    for (final worker in workerRepository.getAll()) {
      if (worker.id == id) return worker;
    }
    return null;
  }

  String formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  IconData vehicleIcon(TransferVehicleType type) {
    switch (type) {
      case TransferVehicleType.bus:
        return Icons.directions_bus;
      case TransferVehicleType.van:
        return Icons.airport_shuttle;
      case TransferVehicleType.pickup:
        return Icons.local_shipping;
      case TransferVehicleType.taxi:
        return Icons.local_taxi;
    }
  }

  String workerSummary(Transfer transfer) {
    final names = transfer.workerIds
        .map(_worker)
        .whereType<Worker>()
        .map((worker) => worker.fullName)
        .toList();

    if (names.isEmpty) return 'Sin trabajadores';
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} y ${names.length - 2} más';
  }

  void syncWorkers(Transfer transfer) {
    for (final worker in workerRepository.getAll()) {
      final assigned = transfer.workerIds.contains(worker.id);

      if (assigned) {
        worker.transfer =
            '${transfer.vehicleIdentifier} · ${transfer.departureTime} · '
            '${transfer.origin} → ${transfer.destination}';

        switch (transfer.status) {
          case TransferStatus.scheduled:
          case TransferStatus.boarding:
          case TransferStatus.onRoute:
            worker.status = WorkerStatus.transfer;
          case TransferStatus.completed:
            worker.status = WorkerStatus.atSite;
          case TransferStatus.cancelled:
            if (worker.status == WorkerStatus.transfer) {
              worker.status = WorkerStatus.pending;
            }
        }

        workerRepository.update(worker);
      }
    }
  }

  Future<void> addTransfer() async {
    final transfer = await Navigator.push<Transfer>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TransferFormScreen(initialWorkerId: widget.initialWorkerId),
      ),
    );

    if (!mounted || transfer == null) return;

    transferRepository.add(transfer);
    syncWorkers(transfer);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Traslado creado correctamente.')),
    );
  }

  Future<void> editTransfer(Transfer transfer) async {
    final previousWorkerIds = {...transfer.workerIds};

    final updated = await Navigator.push<Transfer>(
      context,
      MaterialPageRoute(builder: (_) => TransferFormScreen(transfer: transfer)),
    );

    if (!mounted || updated == null) return;

    transferRepository.update(updated);

    for (final workerId in previousWorkerIds.difference(
      updated.workerIds.toSet(),
    )) {
      final worker = _worker(workerId);
      if (worker != null) {
        worker.transfer = '';
        if (worker.status == WorkerStatus.transfer) {
          worker.status = WorkerStatus.pending;
        }
        workerRepository.update(worker);
      }
    }

    syncWorkers(updated);
    setState(() {});
  }

  Future<void> deleteTransfer(Transfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar traslado'),
        content: Text(
          'Se eliminará ${transfer.code} y se quitará de los trabajadores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final workerId in transfer.workerIds) {
      final worker = _worker(workerId);
      if (worker != null) {
        worker.transfer = '';
        if (worker.status == WorkerStatus.transfer) {
          worker.status = WorkerStatus.pending;
        }
        workerRepository.update(worker);
      }
    }

    transferRepository.delete(transfer.id);
    setState(() {});
  }

  Future<void> controlPassengers(Transfer transfer) async {
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

  int count(TransferStatus status) {
    return transferRepository
        .getAll()
        .where((transfer) => transfer.status == status)
        .length;
  }

  Widget _serviceGroupsSummary() {
    final groups = serviceGroups;

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: groups.entries.map((entry) {
          final group = entry.value;
          final first = group.first;
          final totals = _serviceGroupTotals(group);

          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransferServiceGroupScreen(serviceGroupId: entry.key),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${first.purpose.label} · ${formatDate(first.date)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${first.origin} → ${first.destination}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            totals.pending == 0
                                ? 'Jornada completa'
                                : '${totals.pending} pendiente(s)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _serviceGroupMetric(
                          icon: Icons.directions_bus_rounded,
                          label: 'Buses',
                          value: totals.buses,
                        ),
                        _serviceGroupMetric(
                          icon: Icons.groups_rounded,
                          label: 'Esperados',
                          value: totals.expected,
                        ),
                        _serviceGroupMetric(
                          icon: Icons.directions_bus_filled_rounded,
                          label: 'Abordaron',
                          value: totals.boarded,
                        ),
                        _serviceGroupMetric(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Llegaron',
                          value: totals.arrived,
                        ),
                        _serviceGroupMetric(
                          icon: Icons.warning_amber_rounded,
                          label: 'Pendientes',
                          value: totals.pending,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _serviceGroupMetric({
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

  @override
  Widget build(BuildContext context) {
    final filtered = transfers;

    return Column(
      children: [
        _summary(),
        _serviceGroupsSummary(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              children: [
                _filters(),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('No se encontraron traslados.'),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final transfer = filtered[index];

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 27,
                                      child: Icon(
                                        vehicleIcon(transfer.vehicleType),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                transfer.code,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                transfer.vehicleIdentifier,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${transfer.origin} → '
                                            '${transfer.destination}',
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${formatDate(transfer.date)} · '
                                            '${transfer.departureTime} · '
                                            '${transfer.driverName} · '
                                            '${transfer.licensePlate}',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${workerSummary(transfer)} · '
                                            '${transfer.workerIds.length}/'
                                            '${transfer.capacity} pasajeros',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 2),

                                          const SizedBox(height: 4),

                                          Text(
                                            '${transfer.expectedPassengers} esperados · '
                                            '${transfer.boardedPassengers} abordaron · '
                                            '${transfer.arrivedPassengers} llegaron · '
                                            '${transfer.pendingPassengers} por llegar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  transfer.pendingPassengers > 0
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFF16A36A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TransferStatusChip(status: transfer.status),
                                    const SizedBox(width: 6),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'control') {
                                          controlPassengers(transfer);
                                        }
                                        if (value == 'edit') {
                                          editTransfer(transfer);
                                        }
                                        if (value == 'delete') {
                                          deleteTransfer(transfer);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'control',
                                          child: ListTile(
                                            dense: true,
                                            leading: Icon(
                                              Icons.fact_check_outlined,
                                            ),
                                            title: Text('Controlar pasajeros'),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            dense: true,
                                            leading: Icon(Icons.edit),
                                            title: Text('Editar'),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            dense: true,
                                            leading: Icon(Icons.delete_outline),
                                            title: Text('Eliminar'),
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
        ),
      ],
    );
  }

  Widget _summary() {
    final all = transferRepository.getAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayCount = all.where((transfer) {
      final value = DateTime(
        transfer.date.year,
        transfer.date.month,
        transfer.date.day,
      );
      return value == today;
    }).length;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 900
              ? (constraints.maxWidth - 48) / 4
              : (constraints.maxWidth - 16) / 2;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _summaryCard(
                width: itemWidth,
                title: 'Traslados hoy',
                value: todayCount.toString(),
                icon: Icons.today,
                color: Colors.indigo,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Programados',
                value: count(TransferStatus.scheduled).toString(),
                icon: Icons.schedule,
                color: AppColors.warning,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'En ruta',
                value: count(TransferStatus.onRoute).toString(),
                icon: Icons.route,
                color: Colors.deepOrange,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Finalizados',
                value: count(TransferStatus.completed).toString(),
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(title),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final search = TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText:
                'Buscar trabajador, código, ruta, vehículo, patente o conductor',
            prefixIcon: Icon(Icons.search),
          ),
        );

        final status = DropdownButtonFormField<TransferStatus?>(
          initialValue: selectedStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estado',
            prefixIcon: Icon(Icons.filter_alt),
          ),
          items: [
            const DropdownMenuItem<TransferStatus?>(
              value: null,
              child: Text('Todos los estados'),
            ),
            ...TransferStatus.values.map(
              (item) => DropdownMenuItem<TransferStatus?>(
                value: item,
                child: Text(item.label),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => selectedStatus = value);
          },
        );

        final add = FilledButton.icon(
          onPressed: addTransfer,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo traslado'),
        );

        final addServiceGroup = OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransferServiceGroupFormScreen(),
              ),
            );

            if (mounted) {
              setState(() {});
            }
          },
          icon: const Icon(Icons.alt_route_rounded),
          label: const Text('Nueva jornada'),
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 12),
              status,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: add),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: addServiceGroup),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: 12),
            Expanded(child: status),
            const SizedBox(width: 12),
            addServiceGroup,
            const SizedBox(width: 8),
            add,
          ],
        );
      },
    );
  }
}
