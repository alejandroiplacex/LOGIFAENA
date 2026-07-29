import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/sync/audit_entry.dart';
import '../../../core/sync/audit_service.dart';
import '../../../core/sync/pending_sync_operation.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/sync/sync_status.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({
    super.key,
    this.operationsLoader,
    this.auditLoader,
    this.retryOperation,
    this.removeOperation,
    this.auditRecorder,
  });

  final List<PendingSyncOperation> Function()? operationsLoader;
  final List<AuditEntry> Function()? auditLoader;
  final Future<void> Function(int id)? retryOperation;
  final Future<void> Function(int id)? removeOperation;
  final Future<int> Function({
    required String action,
    required String entityType,
    String? details,
  })?
  auditRecorder;

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<PendingSyncOperation> _operations = const [];
  List<AuditEntry> _auditEntries = const [];
  SyncStatus? _filter;
  bool _loading = true;
  Object? _error;
  final Set<int> _busyIds = <int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final operations =
          (widget.operationsLoader ?? SyncQueueService.instance.getAll)();
      final audit = (widget.auditLoader ?? AuditService.instance.getAll)();

      if (!mounted) return;
      setState(() {
        _operations = operations;
        _auditEntries = audit.reversed.toList(growable: false);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  List<PendingSyncOperation> get _filteredOperations {
    final query = _searchController.text.trim().toLowerCase();
    return _operations
        .where((operation) {
          if (_filter != null && operation.status != _filter) return false;
          if (query.isEmpty) return true;

          return operation.entityType.toLowerCase().contains(query) ||
              (operation.entityId ?? '').toLowerCase().contains(query) ||
              operation.operation.toLowerCase().contains(query) ||
              jsonEncode(operation.payload).toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _retry(PendingSyncOperation operation) async {
    final id = operation.id;
    if (id == null || _busyIds.contains(id)) return;

    setState(() => _busyIds.add(id));
    try {
      await (widget.retryOperation ?? SyncQueueService.instance.retry)(id);
      await _recordAudit(
        action: 'sync_retry',
        entityType: operation.entityType,
        details: 'Operación $id devuelta a estado pendiente.',
      );
      if (!mounted) return;
      _showMessage('La operación quedó pendiente para un nuevo envío.');
      _load();
    } catch (_) {
      if (!mounted) return;
      _showMessage('No fue posible reintentar la operación.', isError: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _retryAllFailed() async {
    final failed = _operations
        .where((operation) => operation.status == SyncStatus.failed)
        .toList(growable: false);
    if (failed.isEmpty) {
      _showMessage('No hay operaciones fallidas para reintentar.');
      return;
    }

    var retried = 0;
    for (final operation in failed) {
      final id = operation.id;
      if (id == null) continue;
      try {
        await (widget.retryOperation ?? SyncQueueService.instance.retry)(id);
        retried++;
      } catch (_) {
        // Continúa con las demás operaciones.
      }
    }

    await _recordAudit(
      action: 'sync_retry_batch',
      entityType: 'sync_queue',
      details:
          '$retried de ${failed.length} operaciones fallidas reintentadas.',
    );

    if (!mounted) return;
    _showMessage('$retried operación(es) quedaron pendientes.');
    _load();
  }

  Future<void> _remove(PendingSyncOperation operation) async {
    final id = operation.id;
    if (id == null || _busyIds.contains(id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar operación'),
        content: const Text(
          'La operación se eliminará definitivamente de la cola local. '
          'Esta acción no puede deshacerse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyIds.add(id));
    try {
      await (widget.removeOperation ?? SyncQueueService.instance.remove)(id);
      await _recordAudit(
        action: 'sync_remove',
        entityType: operation.entityType,
        details: 'Operación $id eliminada manualmente de la cola.',
      );
      if (!mounted) return;
      _showMessage('Operación eliminada.');
      _load();
    } catch (_) {
      if (!mounted) return;
      _showMessage('No fue posible eliminar la operación.', isError: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _recordAudit({
    required String action,
    required String entityType,
    String? details,
  }) async {
    final recorder = widget.auditRecorder ?? AuditService.instance.record;
    try {
      await recorder(action: action, entityType: entityType, details: details);
    } catch (_) {
      // Una falla de auditoría no debe bloquear la acción principal.
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showDetails(PendingSyncOperation operation) {
    const encoder = JsonEncoder.withIndent('  ');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${operation.entityType} · ${operation.operation}'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: SelectableText(
              encoder.convert(operation.toJson()),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de sincronización'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sync_alt), text: 'Cola'),
            Tab(icon: Icon(Icons.history), text: 'Auditoría'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildQueueTab(), _buildAuditTab()],
      ),
    );
  }

  Widget _buildQueueTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorState(onRetry: _load);
    }

    final operations = _filteredOperations;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Buscar por entidad, identificador o contenido',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<SyncStatus?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('Todas')),
                          ButtonSegment(
                            value: SyncStatus.pending,
                            label: Text('Pendientes'),
                          ),
                          ButtonSegment(
                            value: SyncStatus.sending,
                            label: Text('Enviando'),
                          ),
                          ButtonSegment(
                            value: SyncStatus.completed,
                            label: Text('Completadas'),
                          ),
                          ButtonSegment(
                            value: SyncStatus.failed,
                            label: Text('Fallidas'),
                          ),
                        ],
                        selected: <SyncStatus?>{_filter},
                        onSelectionChanged: (selection) {
                          setState(() => _filter = selection.first);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _retryAllFailed,
                    icon: const Icon(Icons.replay),
                    label: const Text('Reintentar fallidas'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: operations.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: operations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final operation = operations[index];
                    final id = operation.id;
                    final busy = id != null && _busyIds.contains(id);
                    return Card(
                      child: ListTile(
                        leading: _StatusIcon(status: operation.status),
                        title: Text(
                          '${operation.entityType} · ${operation.operation}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'ID entidad: ${operation.entityId ?? 'sin identificador'}  ·  '
                          'Intentos: ${operation.attempts}  ·  '
                          '${_formatDate(operation.createdAt)}',
                        ),
                        onTap: () => _showDetails(operation),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Ver detalle',
                              onPressed: busy
                                  ? null
                                  : () => _showDetails(operation),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            if (operation.status == SyncStatus.failed)
                              IconButton(
                                tooltip: 'Reintentar',
                                onPressed: busy
                                    ? null
                                    : () => _retry(operation),
                                icon: busy
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.replay),
                              ),
                            IconButton(
                              tooltip: 'Eliminar',
                              onPressed: busy ? null : () => _remove(operation),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAuditTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorState(onRetry: _load);
    if (_auditEntries.isEmpty) {
      return const Center(
        child: Text('Todavía no hay registros de auditoría.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _auditEntries.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final entry = _auditEntries[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.history, size: 18)),
          title: Text('${entry.action} · ${entry.entityType}'),
          subtitle: Text(entry.details ?? 'Sin información adicional.'),
          trailing: Text(
            _formatDate(entry.occurredAt),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      SyncStatus.pending => Icons.schedule,
      SyncStatus.sending => Icons.cloud_upload_outlined,
      SyncStatus.completed => Icons.check_circle_outline,
      SyncStatus.failed => Icons.error_outline,
    };

    return CircleAvatar(child: Icon(icon));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48),
          SizedBox(height: 12),
          Text('No hay operaciones que coincidan con el filtro.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('No fue posible cargar la información de sincronización.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
