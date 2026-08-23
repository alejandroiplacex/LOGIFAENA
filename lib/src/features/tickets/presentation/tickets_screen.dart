import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/scroll_navigation_buttons.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket.dart';
import 'ticket_form_screen.dart';
import 'widgets/ticket_status_chip.dart';

class TicketsScreen extends StatefulWidget {
  final String? initialWorkerId;

  const TicketsScreen({super.key, this.initialWorkerId});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ticketRepository = InMemoryTicketRepository.instance;
  final workerRepository = InMemoryWorkerRepository.instance;
  final searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listFocusNode = FocusNode(debugLabel: 'TicketsListFocus');
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'TicketsSearchFocus',
  );

  TicketStatus? selectedStatus;
  TicketType? selectedType;
  bool _tableView = true;
  int _selectedIndex = 0;

  double get _rowExtent => _tableView ? 58 : 126;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final initialWorkerId = widget.initialWorkerId;

      if (initialWorkerId != null && initialWorkerId.trim().isNotEmpty) {
        final existingTicket = ticketRepository.findByWorkerId(initialWorkerId);

        if (existingTicket != null) {
          await editTicket(existingTicket);
        } else {
          await addTicket(initialWorkerId: initialWorkerId);
        }

        return;
      }

      _listFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _listFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Ticket> get tickets {
    final query = searchController.text.trim().toLowerCase();

    return ticketRepository.getAll().where((ticket) {
      final worker = _worker(ticket.workerId);
      final workerName = worker?.fullName.toLowerCase() ?? '';
      final rut = worker?.rut.toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          workerName.contains(query) ||
          rut.contains(query) ||
          ticket.company.toLowerCase().contains(query) ||
          ticket.serviceNumber.toLowerCase().contains(query) ||
          ticket.bookingCode.toLowerCase().contains(query) ||
          ticket.origin.toLowerCase().contains(query) ||
          ticket.destination.toLowerCase().contains(query);

      final matchesStatus =
          selectedStatus == null || ticket.status == selectedStatus;
      final matchesType = selectedType == null || ticket.type == selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList()..sort((a, b) {
      final byDate = a.travelDate.compareTo(b.travelDate);
      if (byDate != 0) return byDate;
      return a.travelTime.compareTo(b.travelTime);
    });
  }

  Worker? _worker(String id) {
    for (final worker in workerRepository.getAll()) {
      if (worker.id == id) return worker;
    }
    return null;
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void _syncWorker(Ticket ticket) {
    final worker = _worker(ticket.workerId);
    if (worker == null) return;

    worker.ticket = [
      ticket.company,
      ticket.serviceNumber,
      ticket.bookingCode,
    ].where((value) => value.trim().isNotEmpty).join(' · ');

    if (ticket.status == TicketStatus.issued) {
      if (worker.status == WorkerStatus.pending) {
        worker.status = WorkerStatus.ticketIssued;
      }
    } else if (ticket.status == TicketStatus.cancelled) {
      if (worker.status == WorkerStatus.ticketIssued) {
        worker.status = WorkerStatus.pending;
      }
    }

    workerRepository.update(worker);
  }

  Future<void> addTicket({String? initialWorkerId}) async {
    final ticket = await Navigator.push<Ticket>(
      context,
      MaterialPageRoute(
        builder: (_) => TicketFormScreen(initialWorkerId: initialWorkerId),
      ),
    );

    if (!mounted || ticket == null) return;
    ticketRepository.add(ticket);
    _syncWorker(ticket);
    setState(() => _selectedIndex = tickets.length - 1);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pasaje creado correctamente.')),
    );
  }

  Future<void> editTicket(Ticket ticket) async {
    final updated = await Navigator.push<Ticket>(
      context,
      MaterialPageRoute(builder: (_) => TicketFormScreen(ticket: ticket)),
    );

    if (!mounted || updated == null) return;
    ticketRepository.update(updated);
    _syncWorker(updated);
    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pasaje actualizado.')));
  }

  Future<void> deleteTicket(Ticket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pasaje'),
        content: const Text('Esta acción quitará el pasaje del listado.'),
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
      final worker = _worker(ticket.workerId);
      ticketRepository.delete(ticket.id);
      if (worker != null) {
        worker.ticket = '';
        if (worker.status == WorkerStatus.ticketIssued) {
          worker.status = WorkerStatus.pending;
        }
        workerRepository.update(worker);
      }
      setState(() {
        final length = tickets.length;
        _selectedIndex = length == 0 ? 0 : _selectedIndex.clamp(0, length - 1);
      });
    }
  }

  int count(TicketStatus status) => ticketRepository
      .getAll()
      .where((ticket) => ticket.status == status)
      .length;

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    List<Ticket> filtered,
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
      addTicket();
      return KeyEventResult.handled;
    }

    if (_searchFocusNode.hasFocus) {
      if (key == LogicalKeyboardKey.escape) {
        if (searchController.text.isNotEmpty) {
          searchController.clear();
          setState(() => _selectedIndex = 0);
        } else {
          _listFocusNode.requestFocus();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (filtered.isEmpty) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(filtered, 1, _rowExtent);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(filtered, -1, -_rowExtent);
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
      setState(() => _selectedIndex = 0);
      _animateTo(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      setState(() => _selectedIndex = filtered.length - 1);
      if (_scrollController.hasClients) {
        _animateTo(_scrollController.position.maxScrollExtent);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      final index = _selectedIndex.clamp(0, filtered.length - 1);
      editTicket(filtered[index]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (searchController.text.isNotEmpty ||
          selectedStatus != null ||
          selectedType != null) {
        searchController.clear();
        setState(() {
          selectedStatus = null;
          selectedType = null;
          _selectedIndex = 0;
        });
        _animateTo(0);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _moveSelection(List<Ticket> filtered, int delta, double scrollDelta) {
    final next = (_selectedIndex + delta).clamp(0, filtered.length - 1);
    setState(() => _selectedIndex = next);
    if (_scrollController.hasClients) {
      _animateTo(_scrollController.offset + scrollDelta);
    }
  }

  void _pageScroll(List<Ticket> filtered, int direction) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final rows = (viewport / _rowExtent).floor().clamp(1, filtered.length);
    final next = (_selectedIndex + (rows * direction)).clamp(
      0,
      filtered.length - 1,
    );
    setState(() => _selectedIndex = next);
    _animateTo(_scrollController.offset + (viewport * 0.85 * direction));
  }

  void _animateTo(double offset) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = tickets;
    if (filtered.isNotEmpty && _selectedIndex >= filtered.length) {
      _selectedIndex = filtered.length - 1;
    }

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
                const SizedBox(height: 14),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No se encontraron pasajes.'))
                      : Focus(
                          focusNode: _listFocusNode,
                          autofocus: true,
                          onKeyEvent: (node, event) =>
                              _handleKeyEvent(node, event, filtered),
                          child: Column(
                            children: [
                              if (_tableView) _tableHeader(),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Scrollbar(
                                      controller: _scrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      interactive: true,
                                      child: ListView.separated(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.only(
                                          right: 64,
                                          bottom: 90,
                                        ),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, _) => SizedBox(
                                          height: _tableView ? 1 : 12,
                                        ),
                                        itemBuilder: (context, index) {
                                          final ticket = filtered[index];
                                          final selected =
                                              index == _selectedIndex;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => _selectedIndex = index,
                                              );
                                              _listFocusNode.requestFocus();
                                            },
                                            onDoubleTap: () =>
                                                editTicket(ticket),
                                            child: _tableView
                                                ? _ticketTableRow(
                                                    ticket,
                                                    selected: selected,
                                                  )
                                                : _ticketCard(
                                                    ticket,
                                                    selected: selected,
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                    ScrollNavigationButtons(
                                      controller: _scrollController,
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

  Widget _summary() {
    final all = ticketRepository.getAll();
    return Padding(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 1080
              ? (constraints.maxWidth - 64) / 5
              : constraints.maxWidth >= 720
              ? (constraints.maxWidth - 32) / 3
              : (constraints.maxWidth - 16) / 2;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _summaryCard(
                width: itemWidth,
                title: 'Total',
                value: all.length.toString(),
                icon: Icons.airplane_ticket,
                color: Colors.indigo,
                onTap: () => setState(() => selectedStatus = null),
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Solicitados',
                value: count(TicketStatus.requested).toString(),
                icon: Icons.schedule,
                color: AppColors.warning,
                onTap: () =>
                    setState(() => selectedStatus = TicketStatus.requested),
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Emitidos',
                value: count(TicketStatus.issued).toString(),
                icon: Icons.check_circle,
                color: AppColors.success,
                onTap: () =>
                    setState(() => selectedStatus = TicketStatus.issued),
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Reprogramados',
                value: count(TicketStatus.rescheduled).toString(),
                icon: Icons.update,
                color: Colors.deepOrange,
                onTap: () =>
                    setState(() => selectedStatus = TicketStatus.rescheduled),
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Cancelados',
                value: count(TicketStatus.cancelled).toString(),
                icon: Icons.cancel,
                color: AppColors.danger,
                onTap: () =>
                    setState(() => selectedStatus = TicketStatus.cancelled),
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
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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
      ),
    );
  }

  Widget _filters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;

        final search = TextField(
          controller: searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() => _selectedIndex = 0),
          decoration: const InputDecoration(
            labelText: 'Buscar trabajador, RUT, empresa, reserva o ruta',
            prefixIcon: Icon(Icons.search),
          ),
        );

        final status = DropdownButtonFormField<TicketStatus?>(
          initialValue: selectedStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estado',
            prefixIcon: Icon(Icons.filter_alt),
          ),
          items: [
            const DropdownMenuItem<TicketStatus?>(
              value: null,
              child: Text('Todos los estados'),
            ),
            ...TicketStatus.values.map(
              (item) => DropdownMenuItem<TicketStatus?>(
                value: item,
                child: Text(item.label),
              ),
            ),
          ],
          onChanged: (value) => setState(() {
            selectedStatus = value;
            _selectedIndex = 0;
          }),
        );

        final type = DropdownButtonFormField<TicketType?>(
          initialValue: selectedType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tipo',
            prefixIcon: Icon(Icons.route),
          ),
          items: [
            const DropdownMenuItem<TicketType?>(
              value: null,
              child: Text('Todos los tipos'),
            ),
            ...TicketType.values.map(
              (item) => DropdownMenuItem<TicketType?>(
                value: item,
                child: Text(item.label),
              ),
            ),
          ],
          onChanged: (value) => setState(() {
            selectedType = value;
            _selectedIndex = 0;
          }),
        );

        final view = SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.table_rows),
              label: Text('Tabla'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.view_agenda),
              label: Text('Tarjetas'),
            ),
          ],
          selected: {_tableView},
          onSelectionChanged: (values) {
            setState(() => _tableView = values.first);
            _listFocusNode.requestFocus();
          },
        );

        final add = FilledButton.icon(
          onPressed: addTicket,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo pasaje'),
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 12),
                  Expanded(child: type),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: view),
                  const SizedBox(width: 12),
                  Expanded(child: add),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: search),
            const SizedBox(width: 12),
            Expanded(child: status),
            const SizedBox(width: 12),
            Expanded(child: type),
            const SizedBox(width: 12),
            view,
            const SizedBox(width: 12),
            add,
          ],
        );
      },
    );
  }

  Widget _activeFilterBar(int visible) {
    final hasFilters =
        searchController.text.isNotEmpty ||
        selectedStatus != null ||
        selectedType != null;
    return Row(
      children: [
        Text(
          '$visible pasajes visibles',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (hasFilters)
          TextButton.icon(
            onPressed: () {
              searchController.clear();
              setState(() {
                selectedStatus = null;
                selectedType = null;
                _selectedIndex = 0;
              });
              _animateTo(0);
            },
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar filtros'),
          ),
        const SizedBox(width: 8),
        const Tooltip(
          message: 'Ctrl+F buscar · Ctrl+N nuevo · Enter editar · Esc limpiar',
          child: Icon(Icons.keyboard_alt_outlined, color: Colors.black54),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          SizedBox(width: 118, child: Text('Estado', style: style)),
          Expanded(flex: 3, child: Text('Trabajador', style: style)),
          SizedBox(width: 112, child: Text('RUT', style: style)),
          SizedBox(width: 86, child: Text('Tipo', style: style)),
          Expanded(flex: 2, child: Text('Empresa / N°', style: style)),
          Expanded(flex: 2, child: Text('Ruta', style: style)),
          SizedBox(width: 106, child: Text('Fecha', style: style)),
          SizedBox(width: 74, child: Text('Hora', style: style)),
          SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _ticketTableRow(Ticket ticket, {required bool selected}) {
    final worker = _worker(ticket.workerId);
    final primary = Theme.of(context).colorScheme.primary;
    final background = selected
        ? primary.withValues(alpha: 0.10)
        : Theme.of(context).colorScheme.surface;

    Widget text(String value, {int flex = 1, double? width}) {
      final child = Text(
        value.isEmpty ? '—' : value,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
          left: BorderSide(
            color: selected ? primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 118, child: TicketStatusChip(status: ticket.status)),
          text(worker?.fullName ?? 'Trabajador no encontrado', flex: 3),
          text(worker?.rut ?? '', width: 112),
          text(ticket.type.label, width: 86),
          text('${ticket.company} ${ticket.serviceNumber}'.trim(), flex: 2),
          text('${ticket.origin} → ${ticket.destination}', flex: 2),
          text(_date(ticket.travelDate), width: 106),
          text(ticket.travelTime, width: 74),
          SizedBox(
            width: 44,
            child: PopupMenuButton<String>(
              tooltip: 'Acciones',
              onSelected: (value) {
                if (value == 'edit') editTicket(ticket);
                if (value == 'delete') deleteTicket(ticket);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(Ticket ticket, {required bool selected}) {
    final worker = _worker(ticket.workerId);
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? primary : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                child: Icon(
                  ticket.type == TicketType.flight
                      ? Icons.flight
                      : Icons.directions_bus,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker?.fullName ?? 'Trabajador no encontrado',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('${ticket.origin} → ${ticket.destination}'),
                    const SizedBox(height: 2),
                    Text(
                      '${ticket.company} ${ticket.serviceNumber} · '
                      '${_date(ticket.travelDate)} ${ticket.travelTime}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (ticket.bookingCode.isNotEmpty)
                      Text(
                        'Reserva: ${ticket.bookingCode}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
              TicketStatusChip(status: ticket.status),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') editTicket(ticket);
                  if (value == 'delete') deleteTicket(ticket);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBar(List<Ticket> filtered) {
    final total = ticketRepository.getAll().length;
    final selected = filtered.isEmpty
        ? 'Sin selección'
        : '${_selectedIndex + 1} de ${filtered.length}';
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 8, right: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Text('$total pasajes registrados'),
          const SizedBox(width: 18),
          Text('${filtered.length} visibles'),
          const Spacer(),
          Text(selected),
          const SizedBox(width: 16),
          const Icon(Icons.cloud_done, size: 17, color: AppColors.success),
          const SizedBox(width: 5),
          const Text('Base guardada'),
        ],
      ),
    );
  }
}
