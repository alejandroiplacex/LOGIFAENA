import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/operation.dart';

import '../domain/worker.dart';
import '../services/excel_import_service.dart';

class ExcelImportScreen extends StatefulWidget {
  final List<Worker> existingWorkers;

  const ExcelImportScreen({super.key, required this.existingWorkers});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  String? selectedFileName;
  Uint8List? selectedBytes;
  ExcelImportResult? result;
  DuplicateImportPolicy duplicatePolicy = DuplicateImportPolicy.skip;
  bool loading = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _scrollFocusNode = FocusNode(
    debugLabel: 'excel-import-scroll',
  );

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollFocusNode.dispose();
    super.dispose();
  }

  void _moveScroll(double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (_scrollController.offset + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
  }

  void _jumpToScrollEdge({required bool end}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _scrollController.animateTo(
      end ? position.maxScrollExtent : position.minScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Map<ShortcutActivator, VoidCallback> get _scrollShortcuts => {
    const SingleActivator(LogicalKeyboardKey.arrowDown): () => _moveScroll(56),
    const SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveScroll(-56),
    const SingleActivator(LogicalKeyboardKey.pageDown): () => _moveScroll(520),
    const SingleActivator(LogicalKeyboardKey.pageUp): () => _moveScroll(-520),
    const SingleActivator(LogicalKeyboardKey.home): () =>
        _jumpToScrollEdge(end: false),
    const SingleActivator(LogicalKeyboardKey.end): () =>
        _jumpToScrollEdge(end: true),
  };

  Future<void> selectExcel() async {
    setState(() {
      loading = true;
      result = null;
    });

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
      if (picked == null) return;

      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException(
          'No fue posible leer el archivo seleccionado.',
        );
      }

      selectedBytes = bytes;
      selectedFileName = file.name;
      _parseSelectedFile();
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('No fue posible procesar el Excel.\n$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _parseSelectedFile() {
    final bytes = selectedBytes;
    if (bytes == null) return;
    try {
      final parsed = ExcelImportService.parseOperation(
        bytes,
        widget.existingWorkers,
        duplicatePolicy: duplicatePolicy,
      );
      if (!mounted) return;
      setState(() => result = parsed);
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('No fue posible procesar el Excel.\n$error');
    }
  }

  void confirmImport() {
    final current = result;
    final workers = current?.workers ?? const <Worker>[];
    final operation = current?.operation;
    if (current == null || operation == null || operation.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No existen registros válidos para importar.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      ExcelImportPayload(
        fileName: selectedFileName ?? 'Archivo Excel',
        workers: workers,
        operation: operation,
        duplicatePolicy: duplicatePolicy,
        rowsRead: current.rowsRead,
        invalidCount: current.invalidCount,
        duplicateCount: current.duplicateCount,
      ),
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se pudo importar'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = result;
    final readyCount = current?.operation?.workers.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Importar operación desde Excel')),
      body: CallbackShortcuts(
        bindings: _scrollShortcuts,
        child: Focus(
          focusNode: _scrollFocusNode,
          autofocus: true,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              primary: false,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 22, 30, 32),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Importador inteligente multihoja',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Selecciona la plantilla oficial de LogiFaena. El sistema reconocerá Control, Personal, Pasajes, Hoteles, Traslados y las demás hojas de la operación.',
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: loading ? null : selectExcel,
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  loading
                                      ? 'Leyendo archivo...'
                                      : 'Seleccionar archivo .xlsx',
                                ),
                              ),
                              if (selectedFileName != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Archivo: $selectedFileName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              const Text(
                                'Cuando el RUT ya existe:',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<DuplicateImportPolicy>(
                                segments: DuplicateImportPolicy.values
                                    .map(
                                      (policy) =>
                                          ButtonSegment<DuplicateImportPolicy>(
                                            value: policy,
                                            label: Text(policy.label),
                                          ),
                                    )
                                    .toList(),
                                selected: {duplicatePolicy},
                                onSelectionChanged: (selection) {
                                  setState(
                                    () => duplicatePolicy = selection.first,
                                  );
                                  _parseSelectedFile();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (loading)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(36),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      if (current != null) ...[
                        if (current.operationOverview != null) ...[
                          _operationOverview(current.operationOverview!),
                          const SizedBox(height: 16),
                        ],
                        if (current.operation != null) ...[
                          _importDiagnostics(current.operation!),
                          const SizedBox(height: 16),
                        ],
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _metric(
                              'Registros leídos',
                              current.rowsRead,
                              Icons.table_rows,
                            ),
                            _metric(
                              'Listos para procesar',
                              readyCount,
                              Icons.check_circle_outline,
                            ),
                            _metric(
                              'Duplicados detectados',
                              current.duplicateCount,
                              Icons.content_copy,
                            ),
                            _metric(
                              'No importables',
                              current.invalidCount,
                              Icons.warning_amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (current.warnings.isNotEmpty)
                          Card(
                            child: ExpansionTile(
                              initiallyExpanded: current.invalidCount > 0,
                              leading: const Icon(
                                Icons.warning_amber,
                                color: Colors.orange,
                              ),
                              title: Text(
                                '${current.warnings.length} observación(es)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              children: current.warnings
                                  .take(100)
                                  .map(
                                    (warning) => ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                      ),
                                      title: Text(warning),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Vista previa ($readyCount)',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 390,
                                  child:
                                      current.operation == null ||
                                          current.operation!.workers.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No hay trabajadores válidos en la operación.',
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount:
                                              current.operation!.workers.length,
                                          separatorBuilder: (_, _) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final worker = current
                                                .operation!
                                                .workers[index];
                                            return ListTile(
                                              leading: CircleAvatar(
                                                child: Text(
                                                  worker.firstName
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                ),
                                              ),
                                              title: Text(worker.fullName),
                                              subtitle: Text(
                                                '${worker.rut} · ${worker.company}\n${worker.role} · ${worker.project}',
                                              ),
                                              isThreeLine: true,
                                              trailing: Text(
                                                worker.status.label,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: readyCount == 0
                                      ? null
                                      : confirmImport,
                                  icon: const Icon(Icons.file_download_done),
                                  label: Text(
                                    'Importar operación completa ($readyCount trabajadores)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _importDiagnostics(Operation operation) {
    final workerIds = operation.workers.map((item) => item.id).toSet();
    final withTicket = operation.tickets
        .where((item) => workerIds.contains(item.workerId))
        .map((item) => item.workerId)
        .toSet()
        .length;
    final withHotel = operation.hotels
        .where((item) => workerIds.contains(item.workerId))
        .map((item) => item.workerId)
        .toSet()
        .length;
    final withTransfer = operation.transfers
        .expand((item) => item.workerIds)
        .where(workerIds.contains)
        .toSet()
        .length;

    Widget metric(String label, int value, int expected, IconData icon) {
      final ok = value == expected;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ok ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ok ? Colors.green.shade200 : Colors.orange.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: ok ? Colors.green.shade700 : Colors.orange.shade800,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$value / $expected',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: ok ? Colors.green.shade800 : Colors.orange.shade900,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check_outlined),
                SizedBox(width: 10),
                Text(
                  'Diagnóstico antes de importar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Comprueba que cada trabajador esté relacionado por RUT con sus servicios logísticos.',
            ),
            const SizedBox(height: 16),
            metric(
              'Trabajadores con pasaje',
              withTicket,
              operation.workers.length,
              Icons.flight,
            ),
            const SizedBox(height: 10),
            metric(
              'Trabajadores con hotel',
              withHotel,
              operation.workers.length,
              Icons.hotel,
            ),
            const SizedBox(height: 10),
            metric(
              'Trabajadores con traslado',
              withTransfer,
              operation.workers.length,
              Icons.directions_bus,
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                Text('Personal: ${operation.workers.length}'),
                Text('Pasajes: ${operation.tickets.length}'),
                Text('Hoteles: ${operation.hotels.length}'),
                Text('Traslados agrupados: ${operation.transfers.length}'),
                Text('Proveedores: ${operation.providers.length}'),
                Text('Vehículos: ${operation.vehicles.length}'),
                Text('Alertas previstas: ${operation.alerts.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _operationOverview(OperationImportOverview overview) {
    final control = overview.control;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Estructura de la operación',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    overview.issueCount == 0
                        ? Icons.verified
                        : Icons.warning_amber,
                    size: 18,
                  ),
                  label: Text(
                    overview.issueCount == 0
                        ? 'Estructura reconocida'
                        : '${overview.issueCount} incidencia(s)',
                  ),
                ),
              ],
            ),
            if (control.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (control['Empresa'] != null)
                    Chip(label: Text('Empresa: ${control['Empresa']}')),
                  if (control['Proyecto / Faena'] != null)
                    Chip(
                      label: Text('Proyecto: ${control['Proyecto / Faena']}'),
                    ),
                  if (control['Turno'] != null)
                    Chip(label: Text('Turno: ${control['Turno']}')),
                  if (control['Coordinador'] != null)
                    Chip(label: Text('Coordinador: ${control['Coordinador']}')),
                ],
              ),
            ],
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 820
                    ? (constraints.maxWidth - 30) / 4
                    : constraints.maxWidth >= 520
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: overview.sheets.map((sheet) {
                    final ok = sheet.found && !sheet.hasIssues;
                    return SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !sheet.found
                                  ? Icons.cancel_outlined
                                  : ok
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_outlined,
                              color: !sheet.found
                                  ? Colors.red
                                  : ok
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sheet.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    sheet.found
                                        ? '${sheet.rows} registro(s)'
                                        : 'No encontrada',
                                  ),
                                  if (sheet.invalidRows > 0)
                                    Text(
                                      '${sheet.invalidRows} RUT inválido(s)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (sheet.orphanRutRows > 0)
                                    Text(
                                      '${sheet.orphanRutRows} sin trabajador asociado',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            if (overview.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...overview.warnings
                  .take(8)
                  .map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $warning'),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value, IconData icon) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
