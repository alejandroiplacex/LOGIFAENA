import 'package:flutter/material.dart';

import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_result.dart';
import '../../../../core/sync/sync_statistics.dart';
import '../../../../core/sync/sync_statistics_service.dart';
import '../../../sync/presentation/sync_center_screen.dart';

class SyncQueueStatus extends StatefulWidget {
  const SyncQueueStatus({super.key, this.statisticsLoader, this.syncRunner});

  final SyncStatistics Function()? statisticsLoader;
  final Future<SyncRunResult> Function()? syncRunner;

  @override
  State<SyncQueueStatus> createState() => _SyncQueueStatusState();
}

class _SyncQueueStatusState extends State<SyncQueueStatus> {
  SyncStatistics _statistics = const SyncStatistics.empty();
  Object? _error;
  String? _resultMessage;
  bool _isSynchronizing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final loader =
          widget.statisticsLoader ?? SyncStatisticsService.instance.load;
      final statistics = loader();

      if (!mounted) return;
      setState(() {
        _statistics = statistics;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statistics = const SyncStatistics.empty();
        _error = error;
      });
    }
  }

  Future<void> _synchronize() async {
    if (_isSynchronizing) return;

    setState(() {
      _isSynchronizing = true;
      _resultMessage = null;
      _error = null;
    });

    try {
      final runner =
          widget.syncRunner ?? SyncEngine.instance.synchronizePending;
      final result = await runner();

      if (!mounted) return;
      _load();
      setState(() {
        _resultMessage = result.total == 0
            ? 'No había operaciones pendientes.'
            : '${result.completed} completada(s), '
                  '${result.failed} fallida(s) y '
                  '${result.skipped} omitida(s).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _resultMessage = 'No fue posible ejecutar la sincronización.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSynchronizing = false;
        });
      }
    }
  }

  Future<void> _openSyncCenter() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const SyncCenterScreen()));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cola de sincronización',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar estado',
                onPressed: _isSynchronizing ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            const _SyncMessage(
              icon: Icons.warning_amber_rounded,
              text: 'No fue posible leer o procesar la cola de sincronización.',
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SyncMetric(
                  label: 'Pendientes',
                  value: _statistics.pending,
                  icon: Icons.schedule,
                ),
                _SyncMetric(
                  label: 'Enviando',
                  value: _statistics.sending,
                  icon: Icons.cloud_upload_outlined,
                ),
                _SyncMetric(
                  label: 'Completadas',
                  value: _statistics.completed,
                  icon: Icons.check_circle_outline,
                ),
                _SyncMetric(
                  label: 'Fallidas',
                  value: _statistics.failed,
                  icon: Icons.error_outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SyncMessage(
              icon: _statistics.hasProblems
                  ? Icons.warning_amber_rounded
                  : _statistics.hasPendingWork
                  ? Icons.sync_problem
                  : Icons.cloud_done_outlined,
              text: _statusText(_statistics),
            ),
          ],
          if (_resultMessage != null) ...[
            const SizedBox(height: 10),
            _SyncMessage(
              icon: _error == null ? Icons.info_outline : Icons.error_outline,
              text: _resultMessage!,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _isSynchronizing ? null : _openSyncCenter,
                icon: const Icon(Icons.manage_search),
                label: const Text('Administrar cola'),
              ),
              FilledButton.icon(
                onPressed: _isSynchronizing ? null : _synchronize,
                icon: _isSynchronizing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isSynchronizing ? 'Sincronizando...' : 'Sincronizar ahora',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusText(SyncStatistics statistics) {
    if (statistics.hasProblems) {
      return '${statistics.failed} operación(es) requieren revisión.';
    }
    if (statistics.sending > 0) {
      return 'Hay operaciones en proceso de envío.';
    }
    if (statistics.pending > 0) {
      return '${statistics.pending} operación(es) esperan sincronización.';
    }
    if (statistics.total == 0) {
      return 'La cola está vacía.';
    }
    return 'Todas las operaciones registradas están completadas.';
  }
}

class _SyncMetric extends StatelessWidget {
  const _SyncMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 125,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncMessage extends StatelessWidget {
  const _SyncMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
