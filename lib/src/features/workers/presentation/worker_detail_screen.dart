import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../hotels/data/hotel_repository.dart';
import '../../hotels/domain/hotel_assignment.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../tickets/domain/ticket.dart';
import '../../transfers/data/transfer_repository.dart';
import '../../transfers/domain/transfer.dart';
import '../domain/worker.dart';
import 'widgets/worker_status_chip.dart';
import '../services/logistics_readiness_service.dart';
import 'worker_credential_screen.dart';
import '../data/worker_repository.dart';

class WorkerDetailScreen extends StatefulWidget {
  final Worker worker;
  final VoidCallback onEdit;

  const WorkerDetailScreen({
    super.key,
    required this.worker,
    required this.onEdit,
  });

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  Worker get worker => widget.worker;
  VoidCallback get onEdit => widget.onEdit;

  Ticket? get ticket =>
      InMemoryTicketRepository.instance.findByWorkerId(worker.id);

  HotelAssignment? get hotelAssignment =>
      InMemoryHotelRepository.instance.findByWorkerId(worker.id);

  List<Transfer> get transfers {
    final values = InMemoryTransferRepository.instance.findByWorkerId(
      worker.id,
    );
    values.sort((a, b) => b.date.compareTo(a.date));
    return values;
  }

  Transfer? get latestTransfer => transfers.isEmpty ? null : transfers.first;

  String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day-$month-${value.year}';
  }

  String _value(String value) =>
      value.trim().isEmpty ? 'Sin información' : value.trim();

  Widget _row(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.black45),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              _value(value),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTicket = ticket;
    final currentHotel = hotelAssignment;
    final currentTransfer = latestTransfer;
    final readiness = LogisticsReadinessService.evaluate(worker);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Ficha completa del trabajador'),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerCredentialScreen(worker: worker),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.badge_outlined),
            label: const Text('Credencial'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Editar ficha'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          primary: true,
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(readiness),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 820;
                      final personal = _section(
                        title: 'Información personal y laboral',
                        icon: Icons.badge_outlined,
                        children: [
                          _row('RUT', worker.rut),
                          _row('Empresa', worker.company),
                          _row('Cargo', worker.role),
                          _row('Faena / Proyecto', worker.project),
                          _row('Turno', worker.shift),
                          _row('Supervisor', worker.supervisor),
                          _row('Ciudad de origen', worker.city),
                          _row('Teléfono', worker.phone),
                          _row('Correo', worker.email),
                        ],
                      );
                      final emergency = _section(
                        title: 'Contacto y estado operativo',
                        icon: Icons.contact_phone_outlined,
                        children: [
                          _row('Contacto emergencia', worker.emergencyContact),
                          _row('Teléfono emergencia', worker.emergencyPhone),
                          _row('Estado actual', worker.status.label),
                          _row('Observaciones', worker.notes),
                        ],
                      );

                      if (!twoColumns) {
                        return Column(
                          children: [
                            personal,
                            const SizedBox(height: 18),
                            emergency,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: personal),
                          const SizedBox(width: 18),
                          Expanded(child: emergency),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  _presentationControl(),

                  const SizedBox(height: 18),
                  _logisticsOverview(
                    currentTicket,
                    currentHotel,
                    currentTransfer,
                  ),
                  const SizedBox(height: 18),
                  _history(currentTicket, currentHotel),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPresentationStatus(PresentationStatus status) {
    setState(() {
      worker.presentationStatus = status;
      worker.presentationAt = DateTime.now();
    });

    InMemoryWorkerRepository.instance.update(worker);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Presentación actualizada: ${status.label}')),
    );
  }

  Widget _presentationControl() {
    return _section(
      title: 'Control de presentación',
      icon: Icons.how_to_reg_outlined,
      children: [
        const Text(
          'Estado de presentación',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Chip(
              avatar: const Icon(Icons.how_to_reg_outlined, size: 18),
              label: Text(worker.presentationStatus.label),
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      _setPresentationStatus(PresentationStatus.presented),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Presentado'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _setPresentationStatus(PresentationStatus.late),
                  icon: const Icon(Icons.access_time),
                  label: const Text('Presentación tardía'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _setPresentationStatus(PresentationStatus.absent),
                  icon: const Icon(Icons.person_off_outlined),
                  label: const Text('No se presentó'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _header(LogisticsReadiness readiness) {
    final initial = worker.firstName.trim().isEmpty
        ? '?'
        : worker.firstName.trim().substring(0, 1).toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 18,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 650,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${_value(worker.role)} · ${_value(worker.company)} · ${_value(worker.project)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                WorkerStatusChip(status: worker.status),
                const SizedBox(height: 8),
                _readinessChip(readiness),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _readinessChip(LogisticsReadiness readiness) {
    final color = switch (readiness.level) {
      LogisticsReadinessLevel.ready => const Color(0xFF15803D),
      LogisticsReadinessLevel.advanced => const Color(0xFF2563EB),
      LogisticsReadinessLevel.incomplete => const Color(0xFFD97706),
      LogisticsReadinessLevel.critical => const Color(0xFFDC2626),
    };
    final missing = readiness.missingServices.isEmpty
        ? 'Pasaje, hotel y traslado confirmados'
        : 'Falta: ${readiness.missingServices.join(', ')}';
    return Tooltip(
      message: missing,
      child: Chip(
        avatar: Icon(Icons.route_rounded, size: 18, color: color),
        label: Text('${readiness.percentage}% · ${readiness.label}'),
        side: BorderSide(color: color.withValues(alpha: .35)),
        backgroundColor: color.withValues(alpha: .08),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _logisticsOverview(
    Ticket? currentTicket,
    HotelAssignment? currentHotel,
    Transfer? currentTransfer,
  ) {
    return _section(
      title: 'Resumen logístico',
      icon: Icons.route_outlined,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 920
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth >= 600
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _logisticsCard(
                    icon: Icons.airplane_ticket_outlined,
                    title: 'Pasaje',
                    status: currentTicket?.status.label ?? 'Sin registro',
                    rows: currentTicket == null
                        ? [_miniRow('Detalle', worker.ticket)]
                        : [
                            _miniRow('Tipo', currentTicket.type.label),
                            _miniRow('Empresa', currentTicket.company),
                            _miniRow('Servicio', currentTicket.serviceNumber),
                            _miniRow(
                              'Ruta',
                              '${currentTicket.origin} → ${currentTicket.destination}',
                            ),
                            _miniRow(
                              'Fecha',
                              '${_date(currentTicket.travelDate)} · ${currentTicket.travelTime}',
                            ),
                            _miniRow('Reserva', currentTicket.bookingCode),
                          ],
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _logisticsCard(
                    icon: Icons.hotel_outlined,
                    title: 'Alojamiento',
                    status: currentHotel?.status.label ?? 'Sin registro',
                    rows: currentHotel == null
                        ? [
                            _miniRow('Hotel', worker.hotel),
                            _miniRow('Habitación', worker.room),
                          ]
                        : [
                            _miniRow('Hotel', currentHotel.hotelName),
                            _miniRow('Ciudad', currentHotel.city),
                            _miniRow('Habitación', currentHotel.room),
                            _miniRow(
                              'Check-in',
                              _date(currentHotel.checkInDate),
                            ),
                            _miniRow(
                              'Check-out',
                              _date(currentHotel.checkOutDate),
                            ),
                            _miniRow(
                              'Confirmación',
                              currentHotel.confirmationCode,
                            ),
                          ],
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _logisticsCard(
                    icon: Icons.directions_bus_outlined,
                    title: 'Traslado',
                    status: currentTransfer?.status.label ?? 'Sin registro',
                    rows: currentTransfer == null
                        ? [_miniRow('Detalle', worker.transfer)]
                        : [
                            _miniRow(
                              'Vehículo',
                              currentTransfer.vehicleIdentifier,
                            ),
                            _miniRow('Patente', currentTransfer.licensePlate),
                            _miniRow(
                              'Ruta',
                              '${currentTransfer.origin} → ${currentTransfer.destination}',
                            ),
                            _miniRow('Fecha', _date(currentTransfer.date)),
                            _miniRow('Salida', currentTransfer.departureTime),
                            _miniRow('Conductor', currentTransfer.driverName),
                          ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _logisticsCard({
    required IconData icon,
    required String title,
    required String status,
    required List<Widget> rows,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 245),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Chip(label: Text(status)),
          const Divider(height: 24),
          ...rows,
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, height: 1.3),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: _value(value)),
          ],
        ),
      ),
    );
  }

  Widget _history(Ticket? currentTicket, HotelAssignment? currentHotel) {
    final entries = <Widget>[
      _historyEntry(
        Icons.person_add_alt_1,
        'Trabajador registrado',
        '${worker.fullName} fue incorporado a ${_value(worker.project)}.',
      ),
    ];
    if (worker.presentationStatus != PresentationStatus.pending) {
      final presentationAt = worker.presentationAt;

      final presentationTime = presentationAt == null
          ? 'Hora no registrada'
          : '${_date(presentationAt)} '
                '${presentationAt.hour.toString().padLeft(2, '0')}:'
                '${presentationAt.minute.toString().padLeft(2, '0')}';

      final icon = switch (worker.presentationStatus) {
        PresentationStatus.presented => Icons.check_circle_outline,
        PresentationStatus.late => Icons.access_time,
        PresentationStatus.absent => Icons.person_off_outlined,
        PresentationStatus.pending => Icons.schedule,
      };

      entries.add(
        _historyEntry(
          icon,
          worker.presentationStatus.label,
          'Control de presentación · $presentationTime',
        ),
      );
    }
    if (currentTicket != null) {
      entries.add(
        _historyEntry(
          Icons.airplane_ticket_outlined,
          'Pasaje ${currentTicket.status.label.toLowerCase()}',
          '${currentTicket.company} ${currentTicket.serviceNumber} · '
              '${_date(currentTicket.travelDate)} ${currentTicket.travelTime} · '
              '${currentTicket.origin} → ${currentTicket.destination}',
        ),
      );
    }

    if (currentHotel != null) {
      entries.add(
        _historyEntry(
          Icons.hotel_outlined,
          'Alojamiento ${currentHotel.status.label.toLowerCase()}',
          '${currentHotel.hotelName} · Habitación ${_value(currentHotel.room)} · '
              '${_date(currentHotel.checkInDate)} al ${_date(currentHotel.checkOutDate)}',
        ),
      );
    }

    for (final transfer in transfers) {
      final passengerStatus = transfer.statusForWorker(worker.id);

      entries.add(
        _historyEntry(
          Icons.event_available_outlined,
          'Traslado programado',
          '${_date(transfer.date)} ${transfer.departureTime} · '
              '${transfer.origin} → ${transfer.destination} · '
              '${_value(transfer.vehicleIdentifier)}',
        ),
      );

      if (passengerStatus == TransferPassengerStatus.boarded ||
          passengerStatus == TransferPassengerStatus.arrived) {
        entries.add(
          _historyEntry(
            Icons.directions_bus_rounded,
            'Abordó traslado',
            '${transfer.code} · ${transfer.origin} → ${transfer.destination} · '
                '${_value(transfer.vehicleIdentifier)}',
          ),
        );
      }

      if (passengerStatus == TransferPassengerStatus.arrived) {
        entries.add(
          _historyEntry(
            Icons.check_circle_outline,
            'Llegó a destino',
            '${transfer.code} · Destino: ${transfer.destination}',
          ),
        );
      }

      if (transfer.status == TransferStatus.completed) {
        entries.add(
          _historyEntry(
            Icons.task_alt_outlined,
            'Traslado finalizado',
            '${transfer.code} · ${transfer.origin} → ${transfer.destination}',
          ),
        );
      }

      if (transfer.status == TransferStatus.cancelled) {
        entries.add(
          _historyEntry(
            Icons.cancel_outlined,
            'Traslado cancelado',
            '${transfer.code} · ${transfer.origin} → ${transfer.destination}',
          ),
        );
      }
    }

    if (worker.status == WorkerStatus.atSite) {
      entries.add(
        _historyEntry(
          Icons.location_on_outlined,
          'En faena',
          '${worker.fullName} se encuentra en ${_value(worker.project)}.',
        ),
      );
    }

    return _section(
      title: 'Historial de movimientos',
      icon: Icons.history,
      children: entries,
    );
  }

  Widget _historyEntry(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 26),
            ...children,
          ],
        ),
      ),
    );
  }
}
