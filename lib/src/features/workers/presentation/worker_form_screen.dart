import 'package:flutter/material.dart';
import '../domain/worker.dart';

class WorkerFormScreen extends StatefulWidget {
  final Worker? worker;

  const WorkerFormScreen({super.key, this.worker});

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController rut;
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController company;
  late final TextEditingController role;
  late final TextEditingController project;
  late final TextEditingController shift;
  late final TextEditingController supervisor;
  late final TextEditingController city;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController emergencyContact;
  late final TextEditingController emergencyPhone;
  late final TextEditingController hotel;
  late final TextEditingController room;
  late final TextEditingController ticket;
  late final TextEditingController transfer;
  late final TextEditingController notes;
  late WorkerStatus status;

  bool get editing => widget.worker != null;

  @override
  void initState() {
    super.initState();
    final worker = widget.worker;

    rut = TextEditingController(text: worker?.rut ?? '');
    firstName = TextEditingController(text: worker?.firstName ?? '');
    lastName = TextEditingController(text: worker?.lastName ?? '');
    company = TextEditingController(text: worker?.company ?? 'AVA');
    role = TextEditingController(text: worker?.role ?? '');
    project = TextEditingController(text: worker?.project ?? '');
    shift = TextEditingController(text: worker?.shift ?? '10x10');
    supervisor = TextEditingController(text: worker?.supervisor ?? '');
    city = TextEditingController(text: worker?.city ?? '');
    phone = TextEditingController(text: worker?.phone ?? '');
    email = TextEditingController(text: worker?.email ?? '');
    emergencyContact = TextEditingController(
      text: worker?.emergencyContact ?? '',
    );
    emergencyPhone = TextEditingController(text: worker?.emergencyPhone ?? '');
    hotel = TextEditingController(text: worker?.hotel ?? '');
    room = TextEditingController(text: worker?.room ?? '');
    ticket = TextEditingController(text: worker?.ticket ?? '');
    transfer = TextEditingController(text: worker?.transfer ?? '');
    notes = TextEditingController(text: worker?.notes ?? '');
    status = worker?.status ?? WorkerStatus.pending;
  }

  @override
  void dispose() {
    rut.dispose();
    firstName.dispose();
    lastName.dispose();
    company.dispose();
    role.dispose();
    project.dispose();
    shift.dispose();
    supervisor.dispose();
    city.dispose();
    phone.dispose();
    email.dispose();
    emergencyContact.dispose();
    emergencyPhone.dispose();
    hotel.dispose();
    room.dispose();
    ticket.dispose();
    transfer.dispose();
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: required ? requiredField : null,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final worker = Worker(
      id: widget.worker?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      rut: rut.text.trim(),
      firstName: firstName.text.trim(),
      lastName: lastName.text.trim(),
      company: company.text.trim(),
      role: role.text.trim(),
      project: project.text.trim(),
      shift: shift.text.trim(),
      supervisor: supervisor.text.trim(),
      city: city.text.trim(),
      phone: phone.text.trim(),
      email: email.text.trim(),
      emergencyContact: emergencyContact.text.trim(),
      emergencyPhone: emergencyPhone.text.trim(),
      hotel: hotel.text.trim(),
      room: room.text.trim(),
      ticket: ticket.text.trim(),
      transfer: transfer.text.trim(),
      notes: notes.text.trim(),
      status: status,
    );

    Navigator.pop(context, worker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar trabajador' : 'Nuevo trabajador'),
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
                        'Información personal',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formGrid([
                        field(rut, 'RUT', required: true),
                        field(firstName, 'Nombre', required: true),
                        field(lastName, 'Apellido', required: true),
                        field(company, 'Empresa', required: true),
                        field(role, 'Cargo', required: true),
                        field(project, 'Proyecto', required: true),
                        field(shift, 'Turno', required: true),
                        field(supervisor, 'Supervisor'),
                        field(city, 'Ciudad de origen'),
                        field(
                          phone,
                          'Teléfono',
                          keyboardType: TextInputType.phone,
                        ),
                        field(
                          email,
                          'Correo',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        field(emergencyContact, 'Contacto de emergencia'),
                        field(
                          emergencyPhone,
                          'Teléfono de emergencia',
                          keyboardType: TextInputType.phone,
                        ),
                      ]),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Logística',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formGrid([
                        field(hotel, 'Hotel'),
                        field(room, 'Habitación'),
                        field(ticket, 'Pasaje'),
                        field(transfer, 'Traslado'),
                        DropdownButtonFormField<WorkerStatus>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: WorkerStatus.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => status = value);
                            }
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
                          editing ? 'GUARDAR CAMBIOS' : 'CREAR TRABAJADOR',
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
