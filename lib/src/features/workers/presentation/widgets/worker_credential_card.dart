import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/worker.dart';

class WorkerCredentialCard extends StatelessWidget {
  final Worker worker;

  const WorkerCredentialCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final hasIdentity = worker.hasQrIdentity;
    final statusColor = _statusColor(worker.status);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 760;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(company: worker.company, hasIdentity: hasIdentity),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: horizontal
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _IdentityPanel(
                                worker: worker,
                                statusColor: statusColor,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: _QrPanel(
                                worker: worker,
                                hasIdentity: hasIdentity,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _IdentityPanel(
                              worker: worker,
                              statusColor: statusColor,
                            ),
                            const SizedBox(height: 24),
                            _QrPanel(worker: worker, hasIdentity: hasIdentity),
                          ],
                        ),
                ),
                _Footer(worker: worker),
              ],
            );
          },
        ),
      ),
    );
  }

  static Color _statusColor(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.pending:
        return AppColors.pending;
      case WorkerStatus.ticketIssued:
        return AppColors.warning;
      case WorkerStatus.traveling:
        return AppColors.traveling;
      case WorkerStatus.lodging:
        return AppColors.lodging;
      case WorkerStatus.transfer:
        return AppColors.transfer;
      case WorkerStatus.atSite:
        return AppColors.atSite;
      case WorkerStatus.finished:
        return AppColors.finished;
      case WorkerStatus.cancelled:
        return AppColors.cancelled;
    }
  }
}

class _Header extends StatelessWidget {
  final String company;
  final bool hasIdentity;

  const _Header({required this.company, required this.hasIdentity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOGIFAENA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'CREDENCIAL OPERACIONAL',
                  style: TextStyle(
                    color: Color(0xFFD9E8F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            company.trim().isEmpty ? 'EMPRESA' : company.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          Icon(
            hasIdentity ? Icons.verified_outlined : Icons.warning_amber_rounded,
            color: hasIdentity ? Colors.white : AppColors.accentLight,
          ),
        ],
      ),
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  final Worker worker;
  final Color statusColor;

  const _IdentityPanel({required this.worker, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: AppColors.infoSoft,
            child: Text(
              _initials(worker),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.fullName.isEmpty
                      ? 'Trabajador sin nombre'
                      : worker.fullName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_value(worker.role)} · ${_value(worker.company)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _StatusPill(label: worker.status.label, color: statusColor),
                const SizedBox(height: 18),
                const Divider(),
                _DetailRow(label: 'RUT', value: worker.rut),
                _DetailRow(label: 'Proyecto', value: worker.project),
                _DetailRow(label: 'Turno', value: worker.shift),
                _DetailRow(label: 'Supervisor', value: worker.supervisor),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONTACTO DE EMERGENCIA',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _value(worker.emergencyContact),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(_value(worker.emergencyPhone)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(Worker worker) {
    final first = worker.firstName.trim();
    final last = worker.lastName.trim();

    final firstInitial = first.isEmpty ? '' : first[0];
    final lastInitial = last.isEmpty ? '' : last[0];
    final initials = '$firstInitial$lastInitial'.toUpperCase();

    return initials.isEmpty ? 'LF' : initials;
  }

  static String _value(String value) {
    return value.trim().isEmpty ? 'Sin información' : value.trim();
  }
}

class _QrPanel extends StatelessWidget {
  final Worker worker;
  final bool hasIdentity;

  const _QrPanel({required this.worker, required this.hasIdentity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            worker.workerCode.trim().isEmpty
                ? 'SIN CÓDIGO ASIGNADO'
                : worker.workerCode.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (hasIdentity)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: worker.qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            )
          else
            Container(
              width: 248,
              height: 248,
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Identidad QR pendiente de sincronización.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'Presente este código en puntos autorizados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty
        ? 'Sin información'
        : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Worker worker;

  const _Footer({required this.worker});

  @override
  Widget build(BuildContext context) {
    final code = worker.workerCode.trim().isEmpty
        ? 'Identidad pendiente'
        : worker.workerCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      color: AppColors.primaryDark,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ID: $code',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Text(
            'Uso exclusivo LogiFaena',
            style: TextStyle(color: Color(0xFFD9E8F6), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
