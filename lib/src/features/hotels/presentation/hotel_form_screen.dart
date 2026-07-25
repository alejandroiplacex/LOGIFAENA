import 'package:flutter/material.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../domain/hotel_assignment.dart';

class HotelFormScreen extends StatefulWidget {
  final HotelAssignment? assignment;
  final String? initialWorkerId;
  const HotelFormScreen({super.key, this.assignment, this.initialWorkerId});

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen> {
  final formKey = GlobalKey<FormState>();
  final workersRepository = InMemoryWorkerRepository.instance;
  late String workerId;
  late HotelStatus status;
  late DateTime checkInDate;
  late DateTime checkOutDate;
  late final TextEditingController hotelName, city, address, contactName,
      contactPhone, room, dailyRate, confirmationCode, notes;

  List<Worker> get workers => workersRepository.getAll();
  bool get editing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    workerId = a?.workerId ?? widget.initialWorkerId ?? (workers.isNotEmpty ? workers.first.id : '');
    status = a?.status ?? HotelStatus.requested;
    checkInDate = a?.checkInDate ?? DateTime.now();
    checkOutDate = a?.checkOutDate ?? DateTime.now().add(const Duration(days: 1));
    hotelName = TextEditingController(text: a?.hotelName ?? '');
    city = TextEditingController(text: a?.city ?? '');
    address = TextEditingController(text: a?.address ?? '');
    contactName = TextEditingController(text: a?.contactName ?? '');
    contactPhone = TextEditingController(text: a?.contactPhone ?? '');
    room = TextEditingController(text: a?.room ?? '');
    dailyRate = TextEditingController(text: a == null ? '' : a.dailyRate.toStringAsFixed(0));
    confirmationCode = TextEditingController(text: a?.confirmationCode ?? '');
    notes = TextEditingController(text: a?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [hotelName, city, address, contactName, contactPhone, room, dailyRate, confirmationCode, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? requiredField(String? value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;

  Widget field(TextEditingController controller, String label, {bool required = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      validator: required ? requiredField : null,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> pickDate(bool isCheckIn) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? checkInDate : checkOutDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected == null) return;
    setState(() {
      if (isCheckIn) {
        checkInDate = selected;
        if (!checkOutDate.isAfter(checkInDate)) {
          checkOutDate = checkInDate.add(const Duration(days: 1));
        }
      } else {
        checkOutDate = selected;
      }
    });
  }

  String date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  void save() {
    if (!formKey.currentState!.validate()) return;
    if (!checkOutDate.isAfter(checkInDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El check-out debe ser posterior al check-in.')));
      return;
    }
    Navigator.pop(context, HotelAssignment(
      id: widget.assignment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      workerId: workerId,
      hotelName: hotelName.text.trim(),
      city: city.text.trim(),
      address: address.text.trim(),
      contactName: contactName.text.trim(),
      contactPhone: contactPhone.text.trim(),
      room: room.text.trim(),
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      dailyRate: double.tryParse(dailyRate.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
      confirmationCode: confirmationCode.text.trim(),
      notes: notes.text.trim(),
      status: status,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar alojamiento' : 'Nuevo alojamiento')),
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
                      const Text('Trabajador', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: workerId.isEmpty ? null : workerId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Trabajador', prefixIcon: Icon(Icons.person)),
                        items: workers.map((w) => DropdownMenuItem(value: w.id, child: Text('${w.fullName} · ${w.rut}'))).toList(),
                        validator: (value) => value == null ? 'Selecciona un trabajador' : null,
                        onChanged: (value) { if (value != null) setState(() => workerId = value); },
                      ),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('Datos del alojamiento', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _grid([
                        field(hotelName, 'Hotel', required: true),
                        field(city, 'Ciudad', required: true),
                        field(address, 'Dirección'),
                        field(contactName, 'Contacto'),
                        field(contactPhone, 'Teléfono', keyboardType: TextInputType.phone),
                        field(room, 'Habitación', required: true),
                        InkWell(onTap: () => pickDate(true), child: InputDecorator(decoration: const InputDecoration(labelText: 'Check-in', prefixIcon: Icon(Icons.login)), child: Text(date(checkInDate)))),
                        InkWell(onTap: () => pickDate(false), child: InputDecorator(decoration: const InputDecoration(labelText: 'Check-out', prefixIcon: Icon(Icons.logout)), child: Text(date(checkOutDate)))),
                        field(dailyRate, 'Tarifa diaria', keyboardType: TextInputType.number),
                        field(confirmationCode, 'Código de confirmación'),
                        DropdownButtonFormField<HotelStatus>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'Estado'),
                          items: HotelStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                          onChanged: (value) { if (value != null) setState(() => status = value); },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(controller: notes, maxLines: 4, decoration: const InputDecoration(labelText: 'Observaciones', alignLabelWithHint: true)),
                      const SizedBox(height: 22),
                      FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: Text(editing ? 'GUARDAR CAMBIOS' : 'CREAR ALOJAMIENTO')),
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

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth >= 720 ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;
      return Wrap(spacing: 14, runSpacing: 14, children: children.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }
}
