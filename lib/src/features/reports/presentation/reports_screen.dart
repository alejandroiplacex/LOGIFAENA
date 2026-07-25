import 'package:flutter/material.dart';

import '../../alerts/data/operational_alert_service.dart';
import '../../alerts/domain/operational_alert.dart';
import '../../hotels/data/hotel_repository.dart';
import '../../hotels/domain/hotel_assignment.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../tickets/domain/ticket.dart';
import '../../transfers/data/transfer_repository.dart';
import '../../transfers/domain/transfer.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../../../core/theme/app_colors.dart';
import '../services/report_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedProject = 'Todos';
  String _selectedStatus = 'Todos';
  String _selectedCompany = 'Todas';
  String _selectedPeriod = 'Todo el periodo';
  int _selectedSection = 0;

  List<Worker> get _workers => InMemoryWorkerRepository.instance.getAll();
  List<Ticket> get _tickets => InMemoryTicketRepository.instance.getAll();
  List<HotelAssignment> get _hotels =>
      InMemoryHotelRepository.instance.getAll();
  List<Transfer> get _transfers => InMemoryTransferRepository.instance.getAll();
  List<OperationalAlert> get _alerts =>
      OperationalAlertService.instance.getAlerts();

  List<Worker> get _filteredWorkers {
    final query = _searchController.text.trim().toLowerCase();
    return _workers.where((worker) {
      final matchesSearch = query.isEmpty ||
          worker.fullName.toLowerCase().contains(query) ||
          worker.rut.toLowerCase().contains(query) ||
          worker.company.toLowerCase().contains(query) ||
          worker.project.toLowerCase().contains(query);
      final matchesProject =
          _selectedProject == 'Todos' || worker.project == _selectedProject;
      final matchesStatus =
          _selectedStatus == 'Todos' || worker.status.label == _selectedStatus;
      final matchesCompany =
          _selectedCompany == 'Todas' || worker.company == _selectedCompany;
      return matchesSearch && matchesProject && matchesStatus && matchesCompany;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          padding: EdgeInsets.all(viewport.maxWidth < 600 ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildKpis(),
              const SizedBox(height: 20),
              _buildFilters(),
              const SizedBox(height: 20),
              _buildSectionSelector(),
              const SizedBox(height: 16),
              _buildSelectedSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Centro de Inteligencia Operacional',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF13233A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Reportes consolidados para controlar la operación logística.',
              style: TextStyle(color: Color(0xFF6B7A90)),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _exportExcel,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Exportar Excel'),
            ),
            ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generar PDF'),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), actions],
          );
        }
        return Row(children: [Expanded(child: title), actions]);
      },
    );
  }

  Widget _buildKpis() {
    final active = _workers
        .where((worker) =>
            worker.status != WorkerStatus.finished &&
            worker.status != WorkerStatus.cancelled)
        .length;
    final issued =
        _tickets.where((ticket) => ticket.status == TicketStatus.issued).length;
    final confirmedHotels = _hotels
        .where((hotel) =>
            hotel.status == HotelStatus.confirmed ||
            hotel.status == HotelStatus.checkedIn)
        .length;
    final scheduledTransfers = _transfers
        .where((transfer) => transfer.status != TransferStatus.cancelled)
        .length;

    final data = [
      _ReportKpi('Personal activo', '$active', Icons.groups, const Color(0xFF2563EB)),
      _ReportKpi('Pasajes emitidos', '$issued', Icons.airplane_ticket, const Color(0xFFF97316)),
      _ReportKpi('Alojamientos', '$confirmedHotels', Icons.hotel, const Color(0xFF7C3AED)),
      _ReportKpi('Traslados', '$scheduledTransfers', Icons.directions_bus, const Color(0xFF0891B2)),
      _ReportKpi('Alertas abiertas', '${_alerts.length}', Icons.warning_amber, const Color(0xFFDC2626)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1150 ? 5 : width >= 760 ? 3 : width >= 480 ? 2 : 1;
        final spacing = 12.0;
        final itemWidth = (width - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: data
              .map((item) => SizedBox(width: itemWidth, child: _KpiCard(item: item)))
              .toList(),
        );
      },
    );
  }

  Widget _buildFilters() {
    final projects = <String>{
      'Todos',
      ..._workers.map((worker) => worker.project),
    }.toList();
    final statuses = <String>{
      'Todos',
      ...WorkerStatus.values.map((status) => status.label),
    }.toList();
    final companies = <String>{
      'Todas',
      ..._workers.map((worker) => worker.company),
    }.toList();
    const periods = [
      'Todo el periodo',
      'Hoy',
      'Próximos 7 días',
      'Este mes',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final availableWidth = constraints.maxWidth;
          final singleColumn = availableWidth < 560;
          final twoColumns = availableWidth < 980;
          final fieldWidth = singleColumn
              ? availableWidth
              : twoColumns
                  ? (availableWidth - gap) / 2
                  : (availableWidth - gap * 3) / 4;

          final searchWidth = availableWidth;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por trabajador, RUT, empresa o faena',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _FilterDropdown(
                  label: 'Faena',
                  value: _selectedProject,
                  values: projects,
                  onChanged: (value) =>
                      setState(() => _selectedProject = value),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _FilterDropdown(
                  label: 'Estado',
                  value: _selectedStatus,
                  values: statuses,
                  onChanged: (value) =>
                      setState(() => _selectedStatus = value),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _FilterDropdown(
                  label: 'Empresa',
                  value: _selectedCompany,
                  values: companies,
                  onChanged: (value) =>
                      setState(() => _selectedCompany = value),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _FilterDropdown(
                  label: 'Periodo',
                  value: _selectedPeriod,
                  values: periods,
                  onChanged: (value) =>
                      setState(() => _selectedPeriod = value),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionSelector() {
    const sections = [
      ('Resumen ejecutivo', Icons.dashboard_outlined),
      ('Personal', Icons.groups_outlined),
      ('Pasajes', Icons.airplane_ticket_outlined),
      ('Hoteles', Icons.hotel_outlined),
      ('Traslados', Icons.directions_bus_outlined),
      ('Alertas', Icons.warning_amber_outlined),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(sections.length, (index) {
          final selected = index == _selectedSection;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) => setState(() => _selectedSection = index),
              avatar: Icon(
                sections[index].$2,
                size: 18,
                color: selected ? Colors.white : AppColors.primary,
              ),
              label: Text(sections[index].$1),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFDDE5EF)),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case 1:
        return _buildWorkersReport();
      case 2:
        return _buildTicketsReport();
      case 3:
        return _buildHotelsReport();
      case 4:
        return _buildTransfersReport();
      case 5:
        return _buildAlertsReport();
      default:
        return _buildExecutiveSummary();
    }
  }

  Widget _buildExecutiveSummary() {
    final workerStatus = <String, int>{};
    for (final worker in _filteredWorkers) {
      workerStatus.update(worker.status.label, (value) => value + 1,
          ifAbsent: () => 1);
    }

    final projectTotals = <String, int>{};
    for (final worker in _filteredWorkers) {
      projectTotals.update(worker.project, (value) => value + 1,
          ifAbsent: () => 1);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        final left = _SummaryPanel(
          title: 'Distribución por estado',
          subtitle: '${_filteredWorkers.length} trabajadores considerados',
          child: _BarBreakdown(
            values: workerStatus,
            emptyLabel: 'No hay trabajadores con los filtros seleccionados.',
          ),
        );
        final right = _SummaryPanel(
          title: 'Personal por faena',
          subtitle: 'Concentración actual de dotación',
          child: _BarBreakdown(
            values: projectTotals,
            emptyLabel: 'No existen faenas para mostrar.',
          ),
        );
        final coverage = _buildCoveragePanel();

        if (stacked) {
          return Column(
            children: [left, const SizedBox(height: 16), right, const SizedBox(height: 16), coverage],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                Expanded(child: right),
              ],
            ),
            const SizedBox(height: 16),
            coverage,
          ],
        );
      },
    );
  }

  Widget _buildCoveragePanel() {
    final total = _filteredWorkers.length;
    int withTicket = 0;
    int withHotel = 0;
    int withTransfer = 0;
    for (final worker in _filteredWorkers) {
      if (InMemoryTicketRepository.instance.findByWorkerId(worker.id) != null) {
        withTicket++;
      }
      if (InMemoryHotelRepository.instance.findByWorkerId(worker.id) != null) {
        withHotel++;
      }
      if (InMemoryTransferRepository.instance.findByWorkerId(worker.id).isNotEmpty) {
        withTransfer++;
      }
    }

    return _SummaryPanel(
      title: 'Cobertura logística',
      subtitle: 'Nivel de asignación para el personal filtrado',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _CoverageItem('Pasajes', withTicket, total, Icons.airplane_ticket, const Color(0xFFF97316)),
            _CoverageItem('Alojamiento', withHotel, total, Icons.hotel, const Color(0xFF7C3AED)),
            _CoverageItem('Traslados', withTransfer, total, Icons.directions_bus, const Color(0xFF0891B2)),
          ];
          final narrow = constraints.maxWidth < 700;
          if (narrow) {
            return Column(
              children: cards
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CoverageCard(item: item),
                      ))
                  .toList(),
            );
          }
          return Row(
            children: cards
                .map((item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _CoverageCard(item: item),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildWorkersReport() {
    final rows = _filteredWorkers;
    return _ReportTablePanel(
      title: 'Reporte consolidado de personal',
      subtitle: '${rows.length} registros encontrados',
      columns: const ['Trabajador', 'RUT', 'Empresa', 'Faena', 'Turno', 'Estado'],
      rows: rows
          .map((worker) => [
                worker.fullName,
                worker.rut,
                worker.company,
                worker.project,
                worker.shift,
                worker.status.label,
              ])
          .toList(),
    );
  }

  Widget _buildTicketsReport() {
    final workerIds = _filteredWorkers.map((worker) => worker.id).toSet();
    final rows = _tickets.where((ticket) =>
        workerIds.contains(ticket.workerId) && _matchesPeriod(ticket.travelDate)).map((ticket) {
      final worker = _workers.firstWhere((item) => item.id == ticket.workerId);
      return [
        worker.fullName,
        ticket.company,
        ticket.serviceNumber,
        '${ticket.origin} → ${ticket.destination}',
        _formatDate(ticket.travelDate),
        ticket.status.label,
      ];
    }).toList();
    return _ReportTablePanel(
      title: 'Reporte de pasajes',
      subtitle: '${rows.length} pasajes asociados al filtro actual',
      columns: const ['Trabajador', 'Empresa', 'Servicio', 'Ruta', 'Fecha', 'Estado'],
      rows: rows,
    );
  }

  Widget _buildHotelsReport() {
    final workerIds = _filteredWorkers.map((worker) => worker.id).toSet();
    final rows = _hotels.where((hotel) =>
        workerIds.contains(hotel.workerId) && _matchesPeriod(hotel.checkInDate)).map((hotel) {
      final worker = _workers.firstWhere((item) => item.id == hotel.workerId);
      return [
        worker.fullName,
        hotel.hotelName,
        hotel.room.isEmpty ? 'Sin asignar' : hotel.room,
        '${_formatDate(hotel.checkInDate)} - ${_formatDate(hotel.checkOutDate)}',
        '${hotel.nights}',
        hotel.status.label,
      ];
    }).toList();
    return _ReportTablePanel(
      title: 'Reporte de alojamiento',
      subtitle: '${rows.length} asignaciones asociadas al filtro actual',
      columns: const ['Trabajador', 'Hotel', 'Habitación', 'Periodo', 'Noches', 'Estado'],
      rows: rows,
    );
  }

  Widget _buildTransfersReport() {
    final workerIds = _filteredWorkers.map((worker) => worker.id).toSet();
    final rows = _transfers.where((transfer) {
      return transfer.workerIds.any(workerIds.contains) && _matchesPeriod(transfer.date);
    }).map((transfer) => [
          transfer.code,
          transfer.providerCompany,
          transfer.vehicleIdentifier,
          '${transfer.origin} → ${transfer.destination}',
          '${_formatDate(transfer.date)} ${transfer.departureTime}',
          transfer.status.label,
        ]).toList();
    return _ReportTablePanel(
      title: 'Reporte de traslados',
      subtitle: '${rows.length} servicios asociados al filtro actual',
      columns: const ['Código', 'Proveedor', 'Vehículo', 'Ruta', 'Salida', 'Estado'],
      rows: rows,
    );
  }

  Widget _buildAlertsReport() {
    final workerIds = _filteredWorkers.map((worker) => worker.id).toSet();
    final rows = _alerts.where((alert) => workerIds.contains(alert.workerId)).map((alert) => [
          alert.workerName,
          _alertCategoryLabel(alert.category),
          alert.title,
          alert.detail,
          _alertSeverityLabel(alert.severity),
        ]).toList();
    return _ReportTablePanel(
      title: 'Reporte de alertas operacionales',
      subtitle: '${rows.length} alertas pendientes',
      columns: const ['Trabajador', 'Categoría', 'Alerta', 'Detalle', 'Prioridad'],
      rows: rows,
    );
  }

  _ExportPayload get _currentExport {
    final workerIds = _filteredWorkers.map((worker) => worker.id).toSet();
    switch (_selectedSection) {
      case 1:
        return _ExportPayload(
          title: 'Reporte consolidado de personal',
          fileName: 'logifaena_personal',
          columns: const ['Trabajador', 'RUT', 'Empresa', 'Faena', 'Turno', 'Estado'],
          rows: _filteredWorkers.map((worker) => [
            worker.fullName, worker.rut, worker.company, worker.project,
            worker.shift, worker.status.label,
          ]).toList(),
        );
      case 2:
        return _ExportPayload(
          title: 'Reporte de pasajes',
          fileName: 'logifaena_pasajes',
          columns: const ['Trabajador', 'Empresa', 'Servicio', 'Ruta', 'Fecha', 'Estado'],
          rows: _tickets.where((ticket) =>
              workerIds.contains(ticket.workerId) && _matchesPeriod(ticket.travelDate)).map((ticket) {
            final worker = _workers.firstWhere((item) => item.id == ticket.workerId);
            return [worker.fullName, ticket.company, ticket.serviceNumber,
              '${ticket.origin} → ${ticket.destination}', _formatDate(ticket.travelDate), ticket.status.label];
          }).toList(),
        );
      case 3:
        return _ExportPayload(
          title: 'Reporte de alojamiento',
          fileName: 'logifaena_alojamientos',
          columns: const ['Trabajador', 'Hotel', 'Habitación', 'Periodo', 'Noches', 'Estado'],
          rows: _hotels.where((hotel) =>
              workerIds.contains(hotel.workerId) && _matchesPeriod(hotel.checkInDate)).map((hotel) {
            final worker = _workers.firstWhere((item) => item.id == hotel.workerId);
            return [worker.fullName, hotel.hotelName, hotel.room.isEmpty ? 'Sin asignar' : hotel.room,
              '${_formatDate(hotel.checkInDate)} - ${_formatDate(hotel.checkOutDate)}', '${hotel.nights}', hotel.status.label];
          }).toList(),
        );
      case 4:
        return _ExportPayload(
          title: 'Reporte de traslados',
          fileName: 'logifaena_traslados',
          columns: const ['Código', 'Proveedor', 'Vehículo', 'Ruta', 'Salida', 'Estado'],
          rows: _transfers.where((transfer) =>
              transfer.workerIds.any(workerIds.contains) && _matchesPeriod(transfer.date)).map((transfer) => [
            transfer.code, transfer.providerCompany, transfer.vehicleIdentifier,
            '${transfer.origin} → ${transfer.destination}', '${_formatDate(transfer.date)} ${transfer.departureTime}', transfer.status.label,
          ]).toList(),
        );
      case 5:
        return _ExportPayload(
          title: 'Reporte de alertas operacionales',
          fileName: 'logifaena_alertas',
          columns: const ['Trabajador', 'Categoría', 'Alerta', 'Detalle', 'Prioridad'],
          rows: _alerts.where((alert) => workerIds.contains(alert.workerId)).map((alert) => [
            alert.workerName, _alertCategoryLabel(alert.category), alert.title,
            alert.detail, _alertSeverityLabel(alert.severity),
          ]).toList(),
        );
      default:
        return _ExportPayload(
          title: 'Resumen ejecutivo operacional',
          fileName: 'logifaena_resumen_ejecutivo',
          columns: const ['Trabajador', 'Empresa', 'Faena', 'Estado', 'Pasaje', 'Hotel', 'Traslado'],
          rows: _filteredWorkers.map((worker) => [
            worker.fullName, worker.company, worker.project, worker.status.label,
            InMemoryTicketRepository.instance.findByWorkerId(worker.id) == null ? 'Pendiente' : 'Asignado',
            InMemoryHotelRepository.instance.findByWorkerId(worker.id) == null ? 'Pendiente' : 'Asignado',
            InMemoryTransferRepository.instance.findByWorkerId(worker.id).isEmpty ? 'Pendiente' : 'Asignado',
          ]).toList(),
        );
    }
  }

  void _exportExcel() {
    final payload = _currentExport;
    try {
      ReportExportService.exportCsv(
        fileName: payload.fileName,
        title: payload.title,
        columns: payload.columns,
        rows: payload.rows,
      );
      _showSuccess('Archivo compatible con Excel descargado correctamente.');
    } on UnsupportedError catch (error) {
      _showSuccess(error.message?.toString() ?? 'Exportación no disponible en esta plataforma.');
    }
  }

  void _exportPdf() {
    final payload = _currentExport;
    try {
      ReportExportService.printPdf(
        title: payload.title,
        subtitle: '${payload.rows.length} registros · Empresa: $_selectedCompany · Faena: $_selectedProject · Periodo: $_selectedPeriod',
        columns: payload.columns,
        rows: payload.rows,
      );
      _showSuccess('Vista de impresión abierta. Selecciona “Guardar como PDF”.');
    } on UnsupportedError catch (error) {
      _showSuccess(error.message?.toString() ?? 'Impresión no disponible en esta plataforma.');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _matchesPeriod(DateTime date) {
    if (_selectedPeriod == 'Todo el periodo') return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    switch (_selectedPeriod) {
      case 'Hoy':
        return target == today;
      case 'Próximos 7 días':
        final limit = today.add(const Duration(days: 7));
        return !target.isBefore(today) && !target.isAfter(limit);
      case 'Este mes':
        return target.year == now.year && target.month == now.month;
      default:
        return true;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _alertCategoryLabel(AlertCategory category) {
    switch (category) {
      case AlertCategory.ticket:
        return 'Pasaje';
      case AlertCategory.hotel:
        return 'Hotel';
      case AlertCategory.transfer:
        return 'Traslado';
    }
  }

  String _alertSeverityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return 'Crítica';
      case AlertSeverity.medium:
        return 'Media';
      case AlertSeverity.low:
        return 'Baja';
    }
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

class _ExportPayload {
  final String title;
  final String fileName;
  final List<String> columns;
  final List<List<String>> rows;

  const _ExportPayload({
    required this.title,
    required this.fileName,
    required this.columns,
    required this.rows,
  });
}

class _ReportKpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ReportKpi(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _ReportKpi item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 3),
                Text(item.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      selectedItemBuilder: (context) => values
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SummaryPanel({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _BarBreakdown extends StatelessWidget {
  final Map<String, int> values;
  final String emptyLabel;

  const _BarBreakdown({required this.values, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(emptyLabel, style: const TextStyle(color: Color(0xFF64748B)))),
      );
    }
    final maximum = values.values.fold<int>(1, (current, value) => value > current ? value : current);
    return Column(
      children: values.entries.map((entry) {
        final percentage = entry.value / maximum;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: percentage,
                  backgroundColor: const Color(0xFFEAF0F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CoverageItem {
  final String label;
  final int completed;
  final int total;
  final IconData icon;
  final Color color;
  const _CoverageItem(this.label, this.completed, this.total, this.icon, this.color);
}

class _CoverageCard extends StatelessWidget {
  final _CoverageItem item;
  const _CoverageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ratio = item.total == 0 ? 0.0 : item.completed / item.total;
    final percent = (ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color),
              const SizedBox(width: 8),
              Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('$percent%', style: TextStyle(fontWeight: FontWeight.w800, color: item.color)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
          const SizedBox(height: 8),
          Text('${item.completed} de ${item.total} trabajadores cubiertos', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _ReportTablePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> columns;
  final List<List<String>> rows;

  const _ReportTablePanel({
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 42),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 42, color: Color(0xFF94A3B8)),
                    SizedBox(height: 10),
                    Text('No existen registros para los filtros seleccionados.', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columns: columns.map((column) => DataColumn(label: Text(column, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 280), child: Text(cell, overflow: TextOverflow.ellipsis)))).toList())).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
