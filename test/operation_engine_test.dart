import 'package:flutter_test/flutter_test.dart';
import 'package:logifaena_master/src/core/engine/operation_engine.dart';
import 'package:logifaena_master/src/core/models/logistics_alert.dart';
import 'package:logifaena_master/src/features/workers/domain/worker.dart';

void main() {
  test('crea alertas cuando un trabajador no tiene logística asociada', () {
    final worker = Worker(
      id: 'w1',
      rut: '12.345.678-5',
      firstName: 'Ana',
      lastName: 'Pérez',
      company: 'AVA',
      role: 'Operadora',
      project: 'Escondida',
      shift: '10x10',
      supervisor: '',
      city: 'Talca',
      phone: '',
      email: '',
      emergencyContact: '',
      emergencyPhone: '',
      hotel: '',
      room: '',
      ticket: '',
      transfer: '',
      notes: '',
      status: WorkerStatus.pending,
    );

    final operation = const OperationEngine().createOperation(
      id: 'op1',
      company: 'AVA',
      project: 'Escondida',
      shift: '10x10',
      coordinator: 'Alejandro',
      startDate: DateTime(2026, 7, 25),
      endDate: DateTime(2026, 8, 4),
      createdBy: 'Alejandro',
      workers: <Worker>[worker],
    );

    expect(operation.alerts.length, 3);
    expect(
      operation.alerts
          .where((item) => item.severity == LogisticsAlertSeverity.critical)
          .length,
      2,
    );
  });
}
