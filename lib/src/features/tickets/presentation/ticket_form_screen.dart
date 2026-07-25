import 'package:flutter/material.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../domain/ticket.dart';

class TicketFormScreen extends StatefulWidget {
  final Ticket? ticket;
  final String? initialWorkerId;

  const TicketFormScreen({
    super.key,
    this.ticket,
    this.initialWorkerId,
  });

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final formKey = GlobalKey<FormState>();
  final workersRepository = InMemoryWorkerRepository.instance;

  late String workerId;
  late TicketType type;
  late TicketStatus status;
  late DateTime travelDate;

  late final TextEditingController company;
  late final TextEditingController serviceNumber;
  late final TextEditingController bookingCode;
  late final TextEditingController origin;
  late final TextEditingController destination;
  late final TextEditingController travelTime;
  late final TextEditingController baggage;
  late final TextEditingController seat;
  late final TextEditingController notes;

  bool get editing => widget.ticket != null;

  List<Worker> get workers => workersRepository.getAll();

  @override
  void initState() {
    super.initState();
    final ticket = widget.ticket;

    workerId = ticket?.workerId ??
        widget.initialWorkerId ??
        (workers.isNotEmpty ? workers.first.id : '');
    type = ticket?.type ?? TicketType.flight;
    status = ticket?.status ?? TicketStatus.requested;
    travelDate = ticket?.travelDate ?? DateTime.now();

    company = TextEditingController(text: ticket?.company ?? '');
    serviceNumber =
        TextEditingController(text: ticket?.serviceNumber ?? '');
    bookingCode = TextEditingController(text: ticket?.bookingCode ?? '');
    origin = TextEditingController(text: ticket?.origin ?? '');
    destination = TextEditingController(text: ticket?.destination ?? '');
    travelTime = TextEditingController(text: ticket?.travelTime ?? '');
    baggage = TextEditingController(text: ticket?.baggage ?? '');
    seat = TextEditingController(text: ticket?.seat ?? '');
    notes = TextEditingController(text: ticket?.notes ?? '');
  }

  @override
  void dispose() {
    company.dispose();
    serviceNumber.dispose();
    bookingCode.dispose();
    origin.dispose();
    destination.dispose();
    travelTime.dispose();
    baggage.dispose();
    seat.dispose();
    notes.dispose();
    super.dispose();
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: required ? requiredField : null,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: travelDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() => travelDate = selected);
    }
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Ticket(
        id: widget.ticket?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        workerId: workerId,
        type: type,
        company: company.text.trim(),
        serviceNumber: serviceNumber.text.trim(),
        bookingCode: bookingCode.text.trim(),
        origin: origin.text.trim(),
        destination: destination.text.trim(),
        travelDate: travelDate,
        travelTime: travelTime.text.trim(),
        baggage: baggage.text.trim(),
        seat: seat.text.trim(),
        notes: notes.text.trim(),
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar pasaje' : 'Nuevo pasaje'),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Datos del pasajero',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: workerId.isEmpty ? null : workerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Trabajador',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: workers
                            .map(
                              (worker) => DropdownMenuItem(
                                value: worker.id,
                                child: Text(
                                  '${worker.fullName} · ${worker.rut}',
                                ),
                              ),
                            )
                            .toList(),
                        validator: (value) =>
                            value == null ? 'Selecciona un trabajador' : null,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => workerId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Información del viaje',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formGrid([
                        DropdownButtonFormField<TicketType>(
                          value: type,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de pasaje',
                          ),
                          items: TicketType.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => type = value);
                          },
                        ),
                        field(company, 'Empresa / Aerolínea', required: true),
                        field(serviceNumber, 'N° de vuelo o servicio'),
                        field(bookingCode, 'Código de reserva', required: true),
                        field(origin, 'Origen', required: true),
                        field(destination, 'Destino', required: true),
                        InkWell(
                          onTap: pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha de viaje',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              '${travelDate.day.toString().padLeft(2, '0')}/'
                              '${travelDate.month.toString().padLeft(2, '0')}/'
                              '${travelDate.year}',
                            ),
                          ),
                        ),
                        field(travelTime, 'Hora', required: true),
                        field(baggage, 'Equipaje'),
                        field(seat, 'Asiento'),
                        DropdownButtonFormField<TicketStatus>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: TicketStatus.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => status = value);
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notes,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: save,
                        icon: const Icon(Icons.save),
                        label: Text(
                          editing ? 'GUARDAR CAMBIOS' : 'CREAR PASAJE',
                        ),
                      ),
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

  Widget _formGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
