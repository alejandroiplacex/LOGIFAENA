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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CredentialHeader(worker: worker),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.infoSoft,
                    child: Text(
                      _initials(worker),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    worker.fullName.isEmpty
                        ? 'Trabajador sin nombre'
                        : worker.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.workerCode.isEmpty
                        ? 'Sin código asignado'
                        : worker.workerCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        size: 190,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    )
                  else
                    Container(
                      width: 218,
                      height: 218,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Este trabajador aún no tiene identidad QR.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _CredentialDetail(
                    icon: Icons.business_outlined,
                    label: 'Empresa',
                    value: worker.company,
                  ),
                  _CredentialDetail(
                    icon: Icons.location_city_outlined,
                    label: 'Proyecto',
                    value: worker.project,
                  ),
                  _CredentialDetail(
                    icon: Icons.badge_outlined,
                    label: 'Cargo',
                    value: worker.role,
                  ),
                  _CredentialDetail(
                    icon: Icons.calendar_month_outlined,
                    label: 'Turno',
                    value: worker.shift,
                  ),
                  const SizedBox(height: 16),
                  _StatusBadge(status: worker.status),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.surfaceSoft,
              child: Text(
                hasIdentity
                    ? 'Credencial válida para lectura LogiFaena'
                    : 'Identidad QR pendiente de sincronización',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
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
}

class _CredentialHeader extends StatelessWidget {
  final Worker worker;

  const _CredentialHeader({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOGIFAENA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Credencial logística de trabajador',
                  style: TextStyle(color: Color(0xFFD9E8F6), fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            worker.hasQrIdentity
                ? Icons.verified_outlined
                : Icons.warning_amber_rounded,
            color: worker.hasQrIdentity ? Colors.white : AppColors.accentLight,
          ),
        ],
      ),
    );
  }
}

class _CredentialDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CredentialDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? 'Sin información' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WorkerStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
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
