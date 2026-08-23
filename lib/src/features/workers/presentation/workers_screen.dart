import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/repositories/operation_repository.dart';
import '../../../core/widgets/scroll_navigation_buttons.dart';
import '../../hotels/data/hotel_repository.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../transfers/data/transfer_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../data/import_history_repository.dart';
import '../data/worker_repository.dart';
import '../domain/import_history.dart';
import '../domain/worker.dart';
import 'excel_import_screen.dart';
import '../services/excel_import_service.dart';
import 'worker_detail_screen.dart';
import 'worker_form_screen.dart';
import 'widgets/worker_card.dart';
import 'presentation_control_screen.dart';

class WorkersScreen extends StatefulWidget {
  final WorkerStatus? initialStatus;

  const WorkersScreen({super.key, this.initialStatus});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final WorkerRepository repository = InMemoryWorkerRepository.instance;
  final OperationRepository operationRepository =
      InMemoryOperationRepository.instance;
  final TicketRepository ticketRepository = InMemoryTicketRepository.instance;
  final HotelRepository hotelRepository = InMemoryHotelRepository.instance;
  final TransferRepository transferRepository =
      InMemoryTransferRepository.instance;
  final ImportHistoryRepository importHistoryRepository =
      ImportHistoryRepository.instance;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode(debugLabel: 'PersonalListFocus');
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'PersonalSearchFocus',
  );
  int _selectedWorkerIndex = 0;
  bool _tableView = false;

  double get _workerRowExtent => _tableView ? 58 : 132;

  WorkerStatus? selectedStatus;
  String selectedProject = 'Todos';

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _listFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant WorkersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      selectedStatus = widget.initialStatus;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _listScrollController.dispose();
    _listFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Worker> get workers {
    final query = searchController.text.trim().toLowerCase();

    return repository.getAll().where((worker) {
      final matchesSearch =
          query.isEmpty ||
          worker.fullName.toLowerCase().contains(query) ||
          worker.rut.toLowerCase().contains(query) ||
          worker.role.toLowerCase().contains(query) ||
          worker.project.toLowerCase().contains(query) ||
          worker.company.toLowerCase().contains(query);

      final matchesStatus =
          selectedStatus == null || worker.status == selectedStatus;

      final matchesProject =
          selectedProject == 'Todos' || worker.project == selectedProject;

      return matchesSearch && matchesStatus && matchesProject;
    }).toList();
  }

  List<String> get projects {
    final values =
        repository
            .getAll()
            .map((worker) => worker.project)
            .where((project) => project.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['Todos', ...values];
  }

  Future<void> addWorker() async {
    final worker = await Navigator.push<Worker>(
      context,
      MaterialPageRoute(builder: (_) => const WorkerFormScreen()),
    );

    if (!mounted || worker == null) return;

    repository.add(worker);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trabajador creado correctamente.')),
    );
  }

  Future<void> importWorkers() async {
    final payload = await Navigator.push<ExcelImportPayload>(
      context,
      MaterialPageRoute(
        builder: (_) => ExcelImportScreen(existingWorkers: repository.getAll()),
      ),
    );

    if (!mounted || payload == null || payload.operation.workers.isEmpty) {
      return;
    }

    final result = repository.importAll(
      payload.workers,
      updateExisting: payload.duplicatePolicy == DuplicateImportPolicy.update,
    );

    operationRepository.save(payload.operation);
    operationRepository.setActive(payload.operation.id);

    // El Excel multihoja representa la fotografía completa de la operación.
    // Reemplazar elimina registros antiguos, duplicados y relaciones obsoletas.
    ticketRepository.replaceAll(payload.operation.tickets);
    hotelRepository.replaceAll(payload.operation.hotels);
    transferRepository.replaceAll(payload.operation.transfers);

    importHistoryRepository.add(
      ImportHistory(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fileName: payload.fileName,
        importedAt: DateTime.now().toIso8601String(),
        rowsRead: payload.rowsRead,
        created: result.created,
        updated: result.updated,
        skippedOrInvalid:
            payload.invalidCount +
            (payload.duplicatePolicy == DuplicateImportPolicy.skip
                ? payload.duplicateCount
                : 0),
        duplicatePolicy: payload.duplicatePolicy.label,
      ),
    );

    setState(() {
      selectedStatus = null;
      selectedProject = 'Todos';
      searchController.clear();
    });

    await _showImportSummary(
      created: result.created,
      updated: result.updated,
      skipped:
          payload.invalidCount +
          (payload.duplicatePolicy == DuplicateImportPolicy.skip
              ? payload.duplicateCount
              : 0),
      rowsRead: payload.rowsRead,
      tickets: payload.operation.tickets.length,
      hotels: payload.operation.hotels.length,
      transfers: payload.operation.transfers.length,
      alerts: payload.operation.alerts.length,
    );
  }

  Future<void> _showImportSummary({
    required int created,
    required int updated,
    required int skipped,
    required int rowsRead,
    required int tickets,
    required int hotels,
    required int transfers,
    required int alerts,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Importación completada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registros leídos: $rowsRead'),
            const SizedBox(height: 8),
            Text('Nuevos trabajadores: $created'),
            Text('Trabajadores actualizados: $updated'),
            Text('Omitidos o inválidos: $skipped'),
            const Divider(height: 24),
            Text('Pasajes importados: $tickets'),
            Text('Alojamientos importados: $hotels'),
            Text('Traslados importados: $transfers'),
            Text('Alertas operacionales: $alerts'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> showImportHistory() async {
    final items = importHistoryRepository.getAll();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de importaciones'),
        content: SizedBox(
          width: 760,
          height: 420,
          child: items.isEmpty
              ? const Center(
                  child: Text('Todavía no existen importaciones registradas.'),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final date = DateTime.tryParse(item.importedAt);
                    final formattedDate = date == null
                        ? item.importedAt
                        : '${date.day.toString().padLeft(2, '0')}/'
                              '${date.month.toString().padLeft(2, '0')}/'
                              '${date.year} '
                              '${date.hour.toString().padLeft(2, '0')}:'
                              '${date.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.history)),
                      title: Text(item.fileName),
                      subtitle: Text(
                        '$formattedDate · ${item.duplicatePolicy}\n'
                        'Leídos: ${item.rowsRead} · Nuevos: ${item.created} · '
                        'Actualizados: ${item.updated} · Omitidos: ${item.skippedOrInvalid}',
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> openPresentationControl() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PresentationControlScreen()),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> editWorker(Worker worker) async {
    final updated = await Navigator.push<Worker>(
      context,
      MaterialPageRoute(builder: (_) => WorkerFormScreen(worker: worker)),
    );

    if (!mounted || updated == null) return;

    repository.update(updated);
    setState(() {});
  }

  Future<void> openWorker(Worker worker) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerDetailScreen(
          worker: worker,
          onEdit: () {
            Navigator.pop(context);
            editWorker(worker);
          },
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> deleteWorker(Worker worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar trabajador'),
        content: Text('¿Deseas eliminar a ${worker.fullName}?'),
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

    if (confirmed == true) {
      repository.delete(worker.id);
      setState(() {});
    }
  }

  void updateStatus(Worker worker, WorkerStatus status) {
    worker.status = status;
    repository.update(worker);
    setState(() {});
  }

  KeyEventResult _handlePersonalKeyEvent(
    FocusNode node,
    KeyEvent event,
    List<Worker> filtered,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed;

    if (ctrl && key == LogicalKeyboardKey.keyF) {
      _searchFocusNode.requestFocus();
      searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: searchController.text.length,
      );
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyN) {
      addWorker();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyI) {
      importWorkers();
      return KeyEventResult.handled;
    }

    if (_searchFocusNode.hasFocus) {
      if (key == LogicalKeyboardKey.escape) {
        if (searchController.text.isNotEmpty) {
          searchController.clear();
          setState(() => _selectedWorkerIndex = 0);
        } else {
          _listFocusNode.requestFocus();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (filtered.isEmpty) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(filtered, 1, _workerRowExtent);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(filtered, -1, -_workerRowExtent);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _pageScroll(filtered, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _pageScroll(filtered, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      setState(() => _selectedWorkerIndex = 0);
      _animateListTo(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      setState(() => _selectedWorkerIndex = filtered.length - 1);
      if (_listScrollController.hasClients) {
        _animateListTo(_listScrollController.position.maxScrollExtent);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      final index = _selectedWorkerIndex.clamp(0, filtered.length - 1).toInt();
      openWorker(filtered[index]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (searchController.text.isNotEmpty ||
          selectedStatus != null ||
          selectedProject != 'Todos') {
        searchController.clear();
        setState(() {
          selectedStatus = null;
          selectedProject = 'Todos';
          _selectedWorkerIndex = 0;
        });
        _animateListTo(0);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _moveSelection(List<Worker> filtered, int delta, double scrollDelta) {
    final next = (_selectedWorkerIndex + delta)
        .clamp(0, filtered.length - 1)
        .toInt();
    setState(() => _selectedWorkerIndex = next);
    if (_listScrollController.hasClients) {
      _animateListTo(_listScrollController.offset + scrollDelta);
    }
  }

  void _pageScroll(List<Worker> filtered, int direction) {
    if (!_listScrollController.hasClients) return;
    final viewport = _listScrollController.position.viewportDimension;
    final rows = (viewport / _workerRowExtent)
        .floor()
        .clamp(1, filtered.length)
        .toInt();
    final next = (_selectedWorkerIndex + (rows * direction))
        .clamp(0, filtered.length - 1)
        .toInt();
    setState(() => _selectedWorkerIndex = next);
    _animateListTo(
      _listScrollController.offset + (viewport * 0.85 * direction),
    );
  }

  void _animateListTo(double offset) {
    if (!_listScrollController.hasClients) return;
    final position = _listScrollController.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _listScrollController.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = workers;

    return Column(
      children: [
        _summary(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              children: [
                _filters(),
                const SizedBox(height: 10),
                _activeFilterBar(filtered.length),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            selectedStatus == null
                                ? 'No se encontraron trabajadores.'
                                : 'No hay trabajadores con estado ${selectedStatus!.label}.',
                          ),
                        )
                      : Focus(
                          focusNode: _listFocusNode,
                          autofocus: true,
                          onKeyEvent: (node, event) =>
                              _handlePersonalKeyEvent(node, event, filtered),
                          child: Column(
                            children: [
                              if (_tableView) _tableHeader(),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Scrollbar(
                                      controller: _listScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      interactive: true,
                                      child: ListView.separated(
                                        controller: _listScrollController,
                                        padding: const EdgeInsets.only(
                                          right: 64,
                                          bottom: 90,
                                        ),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, _) => SizedBox(
                                          height: _tableView ? 1 : 12,
                                        ),
                                        itemBuilder: (context, index) {
                                          final worker = filtered[index];
                                          final selected =
                                              index == _selectedWorkerIndex;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => _selectedWorkerIndex =
                                                    index,
                                              );
                                              _listFocusNode.requestFocus();
                                            },
                                            onDoubleTap: () =>
                                                openWorker(worker),
                                            child: _tableView
                                                ? _workerTableRow(
                                                    worker,
                                                    selected: selected,
                                                  )
                                                : AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 140,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                      border: Border.all(
                                                        color: selected
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                            : Colors
                                                                  .transparent,
                                                        width: selected ? 2 : 0,
                                                      ),
                                                    ),
                                                    child: WorkerCard(
                                                      worker: worker,
                                                      onOpen: () =>
                                                          openWorker(worker),
                                                      onEdit: () =>
                                                          editWorker(worker),
                                                      onDelete: () =>
                                                          deleteWorker(worker),
                                                      onStatusChanged:
                                                          (status) {
                                                            updateStatus(
                                                              worker,
                                                              status,
                                                            );
                                                          },
                                                    ),
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                    ScrollNavigationButtons(
                                      controller: _listScrollController,
                                      step: 360,
                                    ),
                                  ],
                                ),
                              ),
                              _statusBar(filtered),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF4B5563),
    );

    return Container(
      height: 44,
      margin: const EdgeInsets.only(right: 64, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          SizedBox(width: 150, child: Text('Estado', style: style)),
          Expanded(flex: 3, child: Text('Nombre', style: style)),
          SizedBox(width: 120, child: Text('RUT', style: style)),
          Expanded(flex: 2, child: Text('Empresa', style: style)),
          Expanded(flex: 2, child: Text('Cargo', style: style)),
          Expanded(flex: 2, child: Text('Proyecto', style: style)),
          SizedBox(width: 100, child: Text('Turno', style: style)),
          SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _workerTableRow(Worker worker, {required bool selected}) {
    final primary = Theme.of(context).colorScheme.primary;
    final background = selected
        ? primary.withValues(alpha: 0.10)
        : Theme.of(context).colorScheme.surface;

    Widget value(String text, {int flex = 1, double? width}) {
      final child = Text(
        text.isEmpty ? '—' : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      );
      if (width != null) return SizedBox(width: width, child: child);
      return Expanded(flex: flex, child: child);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 57,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: const BorderSide(color: Color(0xFFE5E7EB)),
          left: BorderSide(
            color: selected ? primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(worker.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  worker.status.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(worker.status),
                  ),
                ),
              ),
            ),
          ),
          value(worker.fullName, flex: 3),
          value(worker.rut, width: 120),
          value(worker.company, flex: 2),
          value(worker.role, flex: 2),
          value(worker.project, flex: 2),
          value(worker.shift, width: 100),
          SizedBox(
            width: 44,
            child: IconButton(
              tooltip: 'Abrir ficha',
              onPressed: () => openWorker(worker),
              icon: const Icon(Icons.open_in_new, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.atSite:
        return AppColors.success;
      case WorkerStatus.transfer:
      case WorkerStatus.traveling:
        return Colors.orange.shade700;
      case WorkerStatus.lodging:
        return Colors.blue.shade700;
      case WorkerStatus.ticketIssued:
        return Colors.indigo.shade600;
      case WorkerStatus.finished:
        return Colors.blueGrey;
      case WorkerStatus.cancelled:
        return AppColors.danger;
      case WorkerStatus.pending:
        return Colors.amber.shade800;
    }
  }

  Widget _statusBar(List<Worker> filtered) {
    final all = repository.getAll();
    final site = all.where((w) => w.status == WorkerStatus.atSite).length;
    final transfer = all.where((w) => w.status == WorkerStatus.transfer).length;

    return Container(
      height: 34,
      margin: const EdgeInsets.only(right: 64, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('${filtered.length} visibles'),
          const Text('  ·  '),
          Text('${all.length} trabajadores'),
          const Text('  ·  '),
          Text('$site en faena'),
          const Text('  ·  '),
          Text('$transfer en traslado'),
          const Spacer(),
          Icon(Icons.cloud_done_outlined, size: 17, color: AppColors.success),
          const SizedBox(width: 6),
          const Text(
            'Base guardada',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final all = repository.getAll();

    int count(WorkerStatus status) {
      return all.where((worker) => worker.status == status).length;
    }

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
                title: 'Total',
                value: all.length.toString(),
                icon: Icons.groups,
                color: Colors.indigo,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'En faena',
                value: count(WorkerStatus.atSite).toString(),
                icon: Icons.engineering,
                color: AppColors.success,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'En traslado',
                value: count(WorkerStatus.transfer).toString(),
                icon: Icons.directions_bus,
                color: Colors.orange,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Pendientes',
                value: count(WorkerStatus.pending).toString(),
                icon: Icons.warning_amber,
                color: AppColors.danger,
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

  Widget _activeFilterBar(int resultCount) {
    final hasFilter =
        selectedStatus != null ||
        selectedProject != 'Todos' ||
        searchController.text.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Text(
            hasFilter
                ? 'Resultados: $resultCount${selectedStatus != null ? ' · Estado: ${selectedStatus!.label}' : ''}'
                : 'Mostrando todos los trabajadores: $resultCount',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (hasFilter)
          TextButton.icon(
            onPressed: () {
              searchController.clear();
              setState(() {
                selectedStatus = null;
                selectedProject = 'Todos';
              });
            },
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar filtros'),
          ),
      ],
    );
  }

  Widget _filters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        final search = TextField(
          controller: searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() => _selectedWorkerIndex = 0),
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre, RUT, cargo, empresa o proyecto',
            prefixIcon: Icon(Icons.search),
          ),
        );

        final status = DropdownButtonFormField<WorkerStatus?>(
          initialValue: selectedStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estado',
            prefixIcon: Icon(Icons.filter_alt),
          ),
          items: [
            const DropdownMenuItem<WorkerStatus?>(
              value: null,
              child: Text('Todos los estados'),
            ),
            ...WorkerStatus.values.map(
              (item) => DropdownMenuItem<WorkerStatus?>(
                value: item,
                child: Text(item.label),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => selectedStatus = value);
          },
        );

        final project = DropdownButtonFormField<String>(
          initialValue: selectedProject,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Proyecto',
            prefixIcon: Icon(Icons.business),
          ),
          items: projects
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            setState(() => selectedProject = value ?? 'Todos');
          },
        );

        final importExcel = FilledButton.tonalIcon(
          onPressed: importWorkers,
          icon: const Icon(Icons.upload_file),
          label: const Text('Importar Excel'),
        );
        final presentationControl = FilledButton.tonalIcon(
          onPressed: openPresentationControl,
          icon: const Icon(Icons.how_to_reg_outlined),
          label: const Text('Control de presentación'),
        );
        final history = OutlinedButton.icon(
          onPressed: showImportHistory,
          icon: const Icon(Icons.history),
          label: const Text('Historial'),
        );

        final add = FilledButton.icon(
          onPressed: addWorker,
          icon: const Icon(Icons.person_add),
          label: const Text('Nuevo trabajador'),
        );

        final viewToggle = SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.view_agenda_outlined),
              label: Text('Tarjetas'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.table_rows_outlined),
              label: Text('Tabla'),
            ),
          ],
          selected: {_tableView},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            setState(() {
              _tableView = selection.first;
              _selectedWorkerIndex = 0;
            });
            _animateListTo(0);
            _listFocusNode.requestFocus();
          },
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 12),
              status,
              const SizedBox(height: 12),
              project,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: viewToggle),
              const SizedBox(height: 12),
              Column(
                children: [
                  SizedBox(width: double.infinity, child: presentationControl),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: history),
                      const SizedBox(width: 8),
                      Expanded(child: importExcel),
                      const SizedBox(width: 8),
                      Expanded(child: add),
                    ],
                  ),
                ],
              ),
            ],
          );
        }

        // Los filtros y las acciones se muestran en filas separadas para que
        // el botón Importar Excel nunca quede oculto por falta de ancho.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: 12),
                Expanded(child: status),
                const SizedBox(width: 12),
                Expanded(child: project),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.table_view, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Carga masiva disponible para archivos .xlsx',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                viewToggle,
                const SizedBox(width: 10),
                presentationControl,
                const SizedBox(width: 10),
                history,
                const SizedBox(width: 10),
                importExcel,
                const SizedBox(width: 12),
                add,
              ],
            ),
          ],
        );
      },
    );
  }
}
