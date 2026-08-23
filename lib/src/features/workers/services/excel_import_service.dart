import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../../core/engine/operation_engine.dart';
import '../../../core/models/operation.dart';
import '../../../core/models/operation_note.dart';
import '../../../core/models/provider.dart';
import '../../../core/models/vehicle.dart';
import '../../hotels/domain/hotel_assignment.dart';
import '../../tickets/domain/ticket.dart';
import '../../transfers/domain/transfer.dart';
import '../domain/worker.dart';

enum DuplicateImportPolicy { skip, update, createNew }

extension DuplicateImportPolicyLabel on DuplicateImportPolicy {
  String get label {
    switch (this) {
      case DuplicateImportPolicy.skip:
        return 'Omitir duplicados';
      case DuplicateImportPolicy.update:
        return 'Actualizar existentes';
      case DuplicateImportPolicy.createNew:
        return 'Crear nuevo registro';
    }
  }
}

class ExcelImportResult {
  final List<Worker> workers;
  final List<String> warnings;
  final int rowsRead;
  final int duplicateCount;
  final int invalidCount;
  final OperationImportOverview? operationOverview;
  final Operation? operation;

  const ExcelImportResult({
    required this.workers,
    required this.warnings,
    required this.rowsRead,
    required this.duplicateCount,
    required this.invalidCount,
    this.operationOverview,
    this.operation,
  });
}

class OperationSheetSummary {
  final String name;
  final bool found;
  final int rows;
  final int invalidRows;
  final int orphanRutRows;

  const OperationSheetSummary({
    required this.name,
    required this.found,
    required this.rows,
    this.invalidRows = 0,
    this.orphanRutRows = 0,
  });

  bool get hasIssues => invalidRows > 0 || orphanRutRows > 0;
}

class OperationImportOverview {
  final List<OperationSheetSummary> sheets;
  final Map<String, String> control;
  final List<String> warnings;

  const OperationImportOverview({
    required this.sheets,
    required this.control,
    required this.warnings,
  });

  int get totalRows => sheets.fold(0, (sum, sheet) => sum + sheet.rows);
  int get issueCount => sheets.fold(
    0,
    (sum, sheet) => sum + sheet.invalidRows + sheet.orphanRutRows,
  );
}

class ExcelImportPayload {
  final String fileName;
  final List<Worker> workers;
  final Operation operation;
  final OperationImportOverview operationOverview;
  final DuplicateImportPolicy duplicatePolicy;
  final int rowsRead;
  final int invalidCount;
  final int duplicateCount;

  const ExcelImportPayload({
    required this.fileName,
    required this.workers,
    required this.operation,
    required this.operationOverview,
    required this.duplicatePolicy,
    required this.rowsRead,
    required this.invalidCount,
    required this.duplicateCount,
  });
}

class _XlsxSheet {
  final String name;
  final List<List<String>> rows;

  const _XlsxSheet(this.name, this.rows);
}

class ExcelImportService {
  /// Importa el libro multihoja oficial y construye una operación logística
  /// completa. Mantiene la política de duplicados aplicada a Personal y usa
  /// el RUT normalizado para relacionar Pasajes, Hoteles, Traslados y Notas.
  static ExcelImportResult parseOperation(
    Uint8List bytes,
    List<Worker> existingWorkers, {
    DuplicateImportPolicy duplicatePolicy = DuplicateImportPolicy.skip,
  }) {
    final workerResult = parseWorkers(
      bytes,
      existingWorkers,
      duplicatePolicy: duplicatePolicy,
    );
    final sheets = _readXlsxWithoutStyles(bytes);
    final overview =
        workerResult.operationOverview ?? _analyzeOperation(sheets);
    final control = overview.control;
    final now = DateTime.now();
    final operationId = _controlValue(control, const [
      'ID Operación',
      'ID Operacion',
      'Operación',
      'Operacion',
    ], fallback: 'OP-${now.microsecondsSinceEpoch}');

    final importedByRut = <String, Worker>{
      for (final worker in workerResult.workers)
        _normalizeRut(worker.rut): worker,
    };
    final existingByRut = <String, Worker>{
      for (final worker in existingWorkers) _normalizeRut(worker.rut): worker,
    };
    final operationWorkers = <Worker>[];
    final seenWorkerIds = <String>{};
    final personal = _sheetByName(sheets, const ['Personal', 'Trabajadores']);
    if (personal != null) {
      final header = _findHeaderRow(
        personal.rows,
        requiredAliases: const [
          ['rut'],
          ['nombre completo', 'nombres', 'nombre'],
        ],
      );
      if (header != null) {
        final headers = _headersFromRow(personal.rows[header]);
        final rutColumn = _findColumn(headers, const ['rut']);
        if (rutColumn != null) {
          for (var i = header + 1; i < personal.rows.length; i++) {
            final rut = _normalizeRut(_valueAt(personal.rows[i], rutColumn));
            if (rut.isEmpty) continue;
            final worker = importedByRut[rut] ?? existingByRut[rut];
            if (worker != null && seenWorkerIds.add(worker.id)) {
              operationWorkers.add(worker);
            }
          }
        }
      }
    }
    for (final worker in workerResult.workers) {
      if (seenWorkerIds.add(worker.id)) operationWorkers.add(worker);
    }

    final workerByRut = <String, Worker>{
      for (final worker in operationWorkers) _normalizeRut(worker.rut): worker,
    };
    final warnings = <String>[...workerResult.warnings, ...overview.warnings];
    final providers = _parseProviders(
      sheets,
      operationId: operationId,
      createdBy: _controlValue(control, const ['Coordinador']),
      warnings: warnings,
    );
    final providerIdByName = <String, String>{
      for (final item in providers) _normalize(item.name): item.id,
    };
    final vehicles = _parseVehicles(
      sheets,
      operationId: operationId,
      createdBy: _controlValue(control, const ['Coordinador']),
      providerIdByName: providerIdByName,
      warnings: warnings,
    );
    final tickets = _parseTickets(sheets, workerByRut, warnings);
    final hotels = _parseHotels(sheets, workerByRut, warnings);
    final transfers = _parseTransfers(sheets, workerByRut, vehicles, warnings);

    final startDate =
        _parseDate(_controlValue(control, const ['Fecha inicio', 'Inicio'])) ??
        _earliestDate(tickets, hotels, transfers) ??
        now;
    final endDate =
        _parseDate(
          _controlValue(control, const [
            'Fecha término',
            'Fecha termino',
            'Término',
            'Termino',
          ]),
        ) ??
        _latestDate(tickets, hotels, transfers) ??
        startDate.add(const Duration(days: 10));

    final engine = const OperationEngine();
    final operation = engine.createOperation(
      id: operationId,
      company: _controlValue(
        control,
        const ['Empresa'],
        fallback: operationWorkers.isEmpty
            ? ''
            : operationWorkers.first.company,
      ),
      project: _controlValue(
        control,
        const ['Proyecto / Faena', 'Proyecto', 'Faena'],
        fallback: operationWorkers.isEmpty
            ? ''
            : operationWorkers.first.project,
      ),
      shift: _controlValue(
        control,
        const ['Turno'],
        fallback: operationWorkers.isEmpty ? '' : operationWorkers.first.shift,
      ),
      coordinator: _controlValue(control, const ['Coordinador']),
      startDate: startDate,
      endDate: endDate.isBefore(startDate) ? startDate : endDate,
      createdBy: _controlValue(control, const [
        'Coordinador',
      ], fallback: 'Importador Excel'),
      workers: operationWorkers,
      tickets: tickets,
      hotels: hotels,
      transfers: transfers,
      providers: providers,
      vehicles: vehicles,
    );
    operation.notes.addAll(
      _parseNotes(
        sheets,
        operationId: operationId,
        workerByRut: workerByRut,
        createdBy: operation.coordinator,
        warnings: warnings,
      ),
    );
    final generalObservation = _controlValue(control, const [
      'Observación general',
      'Observacion general',
    ]);
    if (generalObservation.isNotEmpty) {
      operation.notes.add(
        OperationNote(
          id: '$operationId-NOTE-GENERAL',
          operationId: operationId,
          workerId: null,
          category: 'General',
          message: generalObservation,
          priority: 'Media',
          createdAt: now,
          updatedAt: now,
          createdBy: operation.coordinator,
        ),
      );
    }
    engine.recalculate(operation);

    return ExcelImportResult(
      workers: workerResult.workers,
      warnings: warnings.toSet().toList(),
      rowsRead: workerResult.rowsRead,
      duplicateCount: workerResult.duplicateCount,
      invalidCount: workerResult.invalidCount,
      operationOverview: overview,
      operation: operation,
    );
  }

  static ExcelImportResult parseWorkers(
    Uint8List bytes,
    List<Worker> existingWorkers, {
    DuplicateImportPolicy duplicatePolicy = DuplicateImportPolicy.skip,
  }) {
    final sheets = _readXlsxWithoutStyles(bytes);
    if (sheets.isEmpty) {
      throw const FormatException(
        'El libro fue abierto, pero no se detectaron hojas. Verifica que sea un archivo .xlsx válido.',
      );
    }

    final sheet = sheets.firstWhere((item) {
      final name = _normalize(item.name);
      return name == _normalize('Personal') ||
          name == _normalize('Trabajadores');
    }, orElse: () => sheets.first);
    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw const FormatException('La hoja Personal está vacía.');
    }

    final headerIndex = _findHeaderRow(
      rows,
      requiredAliases: const [
        ['rut'],
        ['nombre completo', 'nombres', 'nombre'],
      ],
    );
    if (headerIndex == null) {
      throw const FormatException(
        'No se encontró la fila de encabezados de la hoja Personal. Debe contener RUT y Nombre completo.',
      );
    }
    final headers = _headersFromRow(rows[headerIndex]);

    final rutColumn = _findColumn(headers, ['rut']);
    final firstNameColumn = _findColumn(headers, [
      'nombre completo',
      'nombres',
      'nombre',
    ]);
    if (rutColumn == null || firstNameColumn == null) {
      throw const FormatException(
        'El Excel debe contener como mínimo las columnas RUT y Nombres.',
      );
    }

    final existingByRut = <String, Worker>{
      for (final worker in existingWorkers)
        if (_normalizeRut(worker.rut).isNotEmpty)
          _normalizeRut(worker.rut): worker,
    };
    final importedRuts = <String>{};
    final imported = <Worker>[];
    final warnings = <String>[];
    var rowsRead = 0;
    var duplicateCount = 0;
    var invalidCount = 0;

    for (var rowIndex = headerIndex + 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      rowsRead++;

      final rut = _valueAt(row, rutColumn);
      final firstName = _valueAt(row, firstNameColumn);
      final explicitLastName = _valueByHeaders(row, headers, [
        'apellidos',
        'apellido',
      ]);
      final nameParts = _splitName(firstName, explicitLastName);
      final importedFirstName = nameParts.$1;
      final lastName = nameParts.$2;

      if (rut.isEmpty || importedFirstName.isEmpty) {
        invalidCount++;
        warnings.add(
          'Fila ${rowIndex + 1}: falta RUT o Nombres; no fue importada.',
        );
        continue;
      }
      if (!_isValidRut(rut)) {
        invalidCount++;
        warnings.add(
          'Fila ${rowIndex + 1}: el RUT $rut no es válido; no fue importada.',
        );
        continue;
      }

      final normalizedRut = _normalizeRut(rut);
      final existing = existingByRut[normalizedRut];
      final repeatedInFile = importedRuts.contains(normalizedRut);
      final isDuplicate = existing != null || repeatedInFile;
      if (isDuplicate) {
        duplicateCount++;
        if (repeatedInFile) {
          warnings.add(
            'Fila ${rowIndex + 1}: el RUT $rut está repetido dentro del Excel; se omitió.',
          );
          continue;
        }
        if (duplicatePolicy == DuplicateImportPolicy.skip) {
          warnings.add(
            'Fila ${rowIndex + 1}: el RUT $rut ya existe; se omitió.',
          );
          continue;
        }
      }

      final email = _valueByHeaders(row, headers, [
        'correo',
        'email',
        'e-mail',
      ]);
      if (email.isNotEmpty && !_looksLikeEmail(email)) {
        warnings.add(
          'Fila ${rowIndex + 1}: correo "$email" con formato dudoso; se importó igualmente.',
        );
      }

      importedRuts.add(normalizedRut);
      final sourceId = _valueByHeaders(row, headers, ['id']);
      final importedId =
          duplicatePolicy == DuplicateImportPolicy.update && existing != null
          ? existing.id
          : (isDuplicate || sourceId.isEmpty
                ? 'IMP-${DateTime.now().microsecondsSinceEpoch}-$rowIndex'
                : sourceId);

      imported.add(
        Worker(
          id: importedId,
          rut: rut,
          firstName: importedFirstName,
          lastName: lastName,
          company: _valueByHeaders(row, headers, ['empresa']),
          role: _valueByHeaders(row, headers, ['cargo', 'funcion', 'función']),
          project: _valueByHeaders(row, headers, [
            'faena/proyecto',
            'faena',
            'proyecto',
            'proyecto / faena',
          ]),
          shift: _valueByHeaders(row, headers, ['turno']),
          supervisor: _valueByHeaders(row, headers, ['supervisor']),
          city: _valueByHeaders(row, headers, [
            'ciudad de origen',
            'ciudad origen',
            'ciudad',
            'origen',
          ]),
          phone: _valueByHeaders(row, headers, [
            'telefono',
            'teléfono',
            'celular',
          ]),
          email: email,
          emergencyContact: _valueByHeaders(row, headers, [
            'contacto de emergencia',
            'contacto emergencia',
          ]),
          emergencyPhone: _valueByHeaders(row, headers, [
            'telefono de emergencia',
            'teléfono de emergencia',
            'telefono emergencia',
          ]),
          hotel: _valueByHeaders(row, headers, ['hotel', 'alojamiento']),
          room: _valueByHeaders(row, headers, ['habitacion', 'habitación']),
          ticket: _valueByHeaders(row, headers, ['pasaje', 'reserva']),
          transfer: _valueByHeaders(row, headers, ['traslado', 'transporte']),
          notes: _valueByHeaders(row, headers, [
            'observaciones',
            'nota',
            'notas',
          ]),
          status: _parseStatus(_valueByHeaders(row, headers, ['estado'])),
        ),
      );
    }

    return ExcelImportResult(
      workers: imported,
      warnings: warnings,
      rowsRead: rowsRead,
      duplicateCount: duplicateCount,
      invalidCount: invalidCount,
      operationOverview: _analyzeOperation(sheets),
    );
  }

  static _XlsxSheet? _sheetByName(List<_XlsxSheet> sheets, List<String> names) {
    final normalized = names.map(_normalize).toSet();
    for (final sheet in sheets) {
      if (normalized.contains(_normalize(sheet.name))) return sheet;
    }
    return null;
  }

  static String _controlValue(
    Map<String, String> control,
    List<String> aliases, {
    String fallback = '',
  }) {
    final normalizedAliases = aliases.map(_normalize).toSet();
    for (final entry in control.entries) {
      if (normalizedAliases.contains(_normalize(entry.key)) &&
          entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    return fallback;
  }

  static List<Ticket> _parseTickets(
    List<_XlsxSheet> sheets,
    Map<String, Worker> workerByRut,
    List<String> warnings,
  ) {
    final sheet = _sheetByName(sheets, const ['Pasajes']);
    if (sheet == null) return <Ticket>[];
    final header = _findHeaderRow(
      sheet.rows,
      requiredAliases: const [
        ['rut'],
      ],
    );
    if (header == null) return <Ticket>[];
    final headers = _headersFromRow(sheet.rows[header]);
    final result = <Ticket>[];
    for (var i = header + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final rut = _normalizeRut(_valueByHeaders(row, headers, const ['rut']));
      final worker = workerByRut[rut];
      if (worker == null) {
        warnings.add('Pasajes fila ${i + 1}: RUT sin trabajador asociado.');
        continue;
      }
      final date = _parseDate(_valueByHeaders(row, headers, const ['fecha']));
      if (date == null) {
        warnings.add('Pasajes fila ${i + 1}: fecha inválida.');
        continue;
      }
      result.add(
        Ticket(
          id: 'TKT-${worker.id}-${i + 1}',
          workerId: worker.id,
          type: _parseTicketType(_valueByHeaders(row, headers, const ['tipo'])),
          company: _valueByHeaders(row, headers, const [
            'aerolínea / empresa',
            'aerolinea / empresa',
            'empresa',
            'aerolínea',
            'aerolinea',
          ]),
          serviceNumber: _valueByHeaders(row, headers, const [
            'n° vuelo / servicio',
            'n vuelo / servicio',
            'vuelo',
            'servicio',
          ]),
          bookingCode: _valueByHeaders(row, headers, const [
            'reserva',
            'código reserva',
            'codigo reserva',
          ]),
          origin: _valueByHeaders(row, headers, const ['origen']),
          destination: _valueByHeaders(row, headers, const ['destino']),
          travelDate: date,
          travelTime: _parseTime(_valueByHeaders(row, headers, const ['hora'])),
          baggage: _valueByHeaders(row, headers, const ['equipaje', 'baggage']),
          seat: _valueByHeaders(row, headers, const ['asiento']),
          notes: _valueByHeaders(row, headers, const [
            'observaciones',
            'notas',
          ]),
          status: _parseTicketStatus(
            _valueByHeaders(row, headers, const ['estado']),
          ),
        ),
      );
    }
    return result;
  }

  static List<HotelAssignment> _parseHotels(
    List<_XlsxSheet> sheets,
    Map<String, Worker> workerByRut,
    List<String> warnings,
  ) {
    final sheet = _sheetByName(sheets, const ['Hoteles']);
    if (sheet == null) return <HotelAssignment>[];
    final header = _findHeaderRow(
      sheet.rows,
      requiredAliases: const [
        ['rut'],
      ],
    );
    if (header == null) return <HotelAssignment>[];
    final headers = _headersFromRow(sheet.rows[header]);
    final result = <HotelAssignment>[];
    for (var i = header + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final worker =
          workerByRut[_normalizeRut(
            _valueByHeaders(row, headers, const ['rut']),
          )];
      if (worker == null) {
        warnings.add('Hoteles fila ${i + 1}: RUT sin trabajador asociado.');
        continue;
      }
      final checkIn = _parseDate(
        _valueByHeaders(row, headers, const [
          'check-in',
          'check in',
          'entrada',
        ]),
      );
      final checkOut = _parseDate(
        _valueByHeaders(row, headers, const [
          'check-out',
          'check out',
          'salida',
        ]),
      );
      if (checkIn == null || checkOut == null) {
        warnings.add('Hoteles fila ${i + 1}: fechas de alojamiento inválidas.');
        continue;
      }
      final hotelName = _valueByHeaders(row, headers, const [
        'hotel',
        'alojamiento',
      ]);
      final room = _valueByHeaders(row, headers, const [
        'habitación',
        'habitacion',
      ]);
      result.add(
        HotelAssignment(
          id: 'HTL-${worker.id}-${i + 1}',
          workerId: worker.id,
          hotelName: hotelName,
          city: _valueByHeaders(row, headers, const ['ciudad']),
          address: _valueByHeaders(row, headers, const [
            'dirección',
            'direccion',
          ]),
          contactName: _valueByHeaders(row, headers, const ['contacto']),
          contactPhone: _valueByHeaders(row, headers, const [
            'teléfono',
            'telefono',
          ]),
          room: room,
          checkInDate: checkIn,
          checkOutDate: checkOut,
          dailyRate: _parseDouble(
            _valueByHeaders(row, headers, const [
              'costo diario',
              'tarifa diaria',
              'costo',
            ]),
          ),
          confirmationCode: _valueByHeaders(row, headers, const [
            'código confirmación',
            'codigo confirmacion',
            'confirmación',
            'confirmacion',
          ]),
          notes: _valueByHeaders(row, headers, const [
            'observaciones',
            'notas',
            'tipo habitación',
            'tipo habitacion',
          ]),
          status: _parseHotelStatus(
            _valueByHeaders(row, headers, const ['estado']),
          ),
        ),
      );
      worker.hotel = hotelName;
      worker.room = room;
    }
    return result;
  }

  static List<Transfer> _parseTransfers(
    List<_XlsxSheet> sheets,
    Map<String, Worker> workerByRut,
    List<Vehicle> vehicles,
    List<String> warnings,
  ) {
    final sheet = _sheetByName(sheets, const ['Traslados']);
    if (sheet == null) return <Transfer>[];
    final header = _findHeaderRow(
      sheet.rows,
      requiredAliases: const [
        ['rut'],
      ],
    );
    if (header == null) return <Transfer>[];
    final headers = _headersFromRow(sheet.rows[header]);
    final byKey = <String, Transfer>{};
    for (var i = header + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final worker =
          workerByRut[_normalizeRut(
            _valueByHeaders(row, headers, const ['rut']),
          )];
      if (worker == null) {
        warnings.add('Traslados fila ${i + 1}: RUT sin trabajador asociado.');
        continue;
      }
      final date = _parseDate(_valueByHeaders(row, headers, const ['fecha']));
      if (date == null) {
        warnings.add('Traslados fila ${i + 1}: fecha inválida.');
        continue;
      }
      final time = _parseTime(_valueByHeaders(row, headers, const ['hora']));
      final origin = _valueByHeaders(row, headers, const ['origen']);
      final destination = _valueByHeaders(row, headers, const ['destino']);
      final plate = _valueByHeaders(row, headers, const ['patente']);
      final provider = _valueByHeaders(row, headers, const ['proveedor']);
      final vehicleText = _valueByHeaders(row, headers, const [
        'vehículo',
        'vehiculo',
      ]);
      final key =
          '${date.toIso8601String()}|$time|${_normalize(origin)}|${_normalize(destination)}|${_normalize(plate)}|${_normalize(provider)}';
      Vehicle? knownVehicle;
      for (final item in vehicles) {
        if (_normalize(item.licensePlate) == _normalize(plate)) {
          knownVehicle = item;
          break;
        }
      }
      final transfer = byKey.putIfAbsent(
        key,
        () => Transfer(
          id: 'TR-${i + 1}',
          code: 'TR-${(byKey.length + 1).toString().padLeft(3, '0')}',
          date: date,
          departureTime: time,
          estimatedArrivalTime: '',
          origin: origin,
          destination: destination,
          routeDescription: '$origin → $destination',
          vehicleType: _parseTransferVehicleType(vehicleText),
          vehicleIdentifier: knownVehicle?.identifier ?? vehicleText,
          licensePlate: plate,
          capacity: knownVehicle?.capacity ?? 0,
          driverName: _valueByHeaders(row, headers, const ['conductor']),
          driverPhone: knownVehicle?.driverPhone ?? '',
          providerCompany: provider,
          workerIds: <String>[],
          notes: _valueByHeaders(row, headers, const [
            'observaciones',
            'notas',
          ]),
          status: _parseTransferStatus(
            _valueByHeaders(row, headers, const ['estado']),
          ),
        ),
      );
      if (!transfer.workerIds.contains(worker.id)) {
        transfer.workerIds.add(worker.id);
      }
      worker.transfer = transfer.code;
    }
    return byKey.values.toList();
  }

  static List<Provider> _parseProviders(
    List<_XlsxSheet> sheets, {
    required String operationId,
    required String createdBy,
    required List<String> warnings,
  }) {
    final sheet = _sheetByName(sheets, const ['Proveedores']);
    if (sheet == null) return <Provider>[];
    final header = _findHeaderRow(sheet.rows, requiredAliases: const []);
    if (header == null) return <Provider>[];
    final headers = _headersFromRow(sheet.rows[header]);
    final result = <Provider>[];
    final usedNames = <String>{};
    for (var i = header + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final name = _valueByHeaders(row, headers, const ['nombre']);
      if (name.isEmpty) {
        warnings.add('Proveedores fila ${i + 1}: falta nombre.');
        continue;
      }
      if (!usedNames.add(_normalize(name))) continue;
      final now = DateTime.now();
      result.add(
        Provider(
          id: _valueByHeaders(row, headers, const [
            'id proveedor',
            'id',
          ], fallback: 'PRV-${i + 1}'),
          operationId: operationId,
          name: name,
          category: _valueByHeaders(row, headers, const [
            'tipo',
            'categoría',
            'categoria',
          ]),
          contactName: _valueByHeaders(row, headers, const ['contacto']),
          phone: _valueByHeaders(row, headers, const ['teléfono', 'telefono']),
          email: _valueByHeaders(row, headers, const ['correo', 'email']),
          address: _valueByHeaders(row, headers, const [
            'dirección',
            'direccion',
            'ciudad',
          ]),
          notes: _valueByHeaders(row, headers, const [
            'observaciones',
            'notas',
          ]),
          active: !_normalize(
            _valueByHeaders(row, headers, const ['estado']),
          ).contains('inactivo'),
          createdAt: now,
          updatedAt: now,
          createdBy: createdBy,
        ),
      );
    }
    return result;
  }

  static List<Vehicle> _parseVehicles(
    List<_XlsxSheet> sheets, {
    required String operationId,
    required String createdBy,
    required Map<String, String> providerIdByName,
    required List<String> warnings,
  }) {
    final sheet = _sheetByName(sheets, const ['Vehículos', 'Vehiculos']);
    if (sheet == null) return <Vehicle>[];
    final header = _findHeaderRow(sheet.rows, requiredAliases: const []);
    if (header == null) return <Vehicle>[];
    final headers = _headersFromRow(sheet.rows[header]);
    final result = <Vehicle>[];
    final usedPlates = <String>{};
    for (var i = header + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final plate = _valueByHeaders(row, headers, const ['patente']);
      if (plate.isEmpty) {
        warnings.add('Vehículos fila ${i + 1}: falta patente.');
        continue;
      }
      if (!usedPlates.add(_normalize(plate))) continue;
      final providerName = _valueByHeaders(row, headers, const ['proveedor']);
      final now = DateTime.now();
      result.add(
        Vehicle(
          id: 'VEH-${i + 1}',
          operationId: operationId,
          identifier: _valueByHeaders(row, headers, const [
            'marca / modelo',
            'marca',
            'modelo',
          ], fallback: plate),
          type: _valueByHeaders(row, headers, const [
            'tipo vehículo',
            'tipo vehiculo',
            'tipo',
          ]),
          licensePlate: plate,
          capacity: _parseInt(
            _valueByHeaders(row, headers, const ['capacidad']),
          ),
          driverName: _valueByHeaders(row, headers, const ['conductor']),
          driverPhone: _valueByHeaders(row, headers, const [
            'teléfono conductor',
            'telefono conductor',
          ]),
          providerId:
              providerIdByName[_normalize(providerName)] ?? providerName,
          status: _valueByHeaders(row, headers, const [
            'estado',
          ], fallback: 'Disponible'),
          notes: _valueByHeaders(row, headers, const [
            'observaciones',
            'notas',
          ]),
          createdAt: now,
          updatedAt: now,
          createdBy: createdBy,
        ),
      );
    }
    return result;
  }

  static List<OperationNote> _parseNotes(
    List<_XlsxSheet> sheets, {
    required String operationId,
    required Map<String, Worker> workerByRut,
    required String createdBy,
    required List<String> warnings,
  }) {
    final sheet = _sheetByName(sheets, const ['Observaciones']);
    if (sheet == null) return <OperationNote>[];
    final header = _findHeaderRow(
      sheet.rows,
      requiredAliases: const [
        ['detalle'],
      ],
    );
    if (header == null) return <OperationNote>[];
    final headers = _headersFromRow(sheet.rows[header]);
    final result = <OperationNote>[];
    for (var i = header + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final rut = _normalizeRut(_valueByHeaders(row, headers, const ['rut']));
      final worker = rut.isEmpty ? null : workerByRut[rut];
      if (rut.isNotEmpty && worker == null) {
        warnings.add(
          'Observaciones fila ${i + 1}: RUT sin trabajador asociado.',
        );
      }
      final message = _valueByHeaders(row, headers, const [
        'detalle',
        'observación',
        'observacion',
      ]);
      if (message.isEmpty) continue;
      final createdAt =
          _parseDate(_valueByHeaders(row, headers, const ['fecha'])) ??
          DateTime.now();
      result.add(
        OperationNote(
          id: '$operationId-NOTE-${i + 1}',
          operationId: operationId,
          workerId: worker?.id,
          category: _valueByHeaders(row, headers, const [
            'tipo',
          ], fallback: 'General'),
          message: message,
          priority: _valueByHeaders(row, headers, const [
            'prioridad',
          ], fallback: 'Media'),
          createdAt: createdAt,
          updatedAt: createdAt,
          createdBy: _valueByHeaders(row, headers, const [
            'responsable',
          ], fallback: createdBy),
        ),
      );
    }
    return result;
  }

  static TicketType _parseTicketType(String value) {
    final normalized = _normalize(value);
    return normalized.contains('bus') || normalized.contains('terrestre')
        ? TicketType.bus
        : TicketType.flight;
  }

  static TicketStatus _parseTicketStatus(String value) {
    final normalized = _normalize(value);
    if (normalized.contains('emit') || normalized.contains('utiliz')) {
      return TicketStatus.issued;
    }
    if (normalized.contains('reprogram')) return TicketStatus.rescheduled;
    if (normalized.contains('cancel')) return TicketStatus.cancelled;
    return TicketStatus.requested;
  }

  static HotelStatus _parseHotelStatus(String value) {
    final normalized = _normalize(value);
    if (normalized.contains('check-in') || normalized.contains('check in')) {
      return HotelStatus.checkedIn;
    }
    if (normalized.contains('check-out') || normalized.contains('check out')) {
      return HotelStatus.checkedOut;
    }
    if (normalized.contains('confirm') || normalized.contains('reserv')) {
      return HotelStatus.confirmed;
    }
    if (normalized.contains('cancel')) return HotelStatus.cancelled;
    return HotelStatus.requested;
  }

  static TransferStatus _parseTransferStatus(String value) {
    final normalized = _normalize(value);
    if (normalized.contains('curso') || normalized.contains('ruta')) {
      return TransferStatus.onRoute;
    }
    if (normalized.contains('embar')) return TransferStatus.boarding;
    if (normalized.contains('complet') || normalized.contains('final')) {
      return TransferStatus.completed;
    }
    if (normalized.contains('cancel')) return TransferStatus.cancelled;
    return TransferStatus.scheduled;
  }

  static TransferVehicleType _parseTransferVehicleType(String value) {
    final normalized = _normalize(value);
    if (normalized.contains('bus') || normalized.contains('minibus')) {
      return TransferVehicleType.bus;
    }
    if (normalized.contains('pickup') || normalized.contains('camioneta')) {
      return TransferVehicleType.pickup;
    }
    if (normalized.contains('taxi')) return TransferVehicleType.taxi;
    return TransferVehicleType.van;
  }

  static DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final serial = double.tryParse(trimmed.replaceAll(',', '.'));
    if (serial != null && serial > 1000) {
      return DateTime(1899, 12, 30).add(Duration(days: serial.floor()));
    }
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;
    final parts = trimmed.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        if (a > 31) return DateTime(a, b, c);
        return DateTime(c < 100 ? 2000 + c : c, b, a);
      }
    }
    return null;
  }

  static String _parseTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final serial = double.tryParse(trimmed.replaceAll(',', '.'));
    if (serial != null && serial >= 0 && serial < 1) {
      final minutes = (serial * 24 * 60).round();
      return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
    }
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(trimmed);
    if (match != null) {
      return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
    }
    return trimmed;
  }

  static double _parseDouble(String value) =>
      double.tryParse(
        value.replaceAll(RegExp(r'[^0-9,.-]'), '').replaceAll(',', '.'),
      ) ??
      0;

  static int _parseInt(String value) => _parseDouble(value).round();

  static DateTime? _earliestDate(
    List<Ticket> tickets,
    List<HotelAssignment> hotels,
    List<Transfer> transfers,
  ) {
    final dates = <DateTime>[
      ...tickets.map((item) => item.travelDate),
      ...hotels.map((item) => item.checkInDate),
      ...transfers.map((item) => item.date),
    ]..sort();
    return dates.isEmpty ? null : dates.first;
  }

  static DateTime? _latestDate(
    List<Ticket> tickets,
    List<HotelAssignment> hotels,
    List<Transfer> transfers,
  ) {
    final dates = <DateTime>[
      ...tickets.map((item) => item.travelDate),
      ...hotels.map((item) => item.checkOutDate),
      ...transfers.map((item) => item.date),
    ]..sort();
    return dates.isEmpty ? null : dates.last;
  }

  static OperationImportOverview _analyzeOperation(List<_XlsxSheet> sheets) {
    const expected = <String>[
      'Control',
      'Personal',
      'Pasajes',
      'Hoteles',
      'Traslados',
      'Observaciones',
      'Proveedores',
      'Vehículos',
    ];
    final byName = <String, _XlsxSheet>{
      for (final sheet in sheets) _normalize(sheet.name): sheet,
    };
    final personalSheet =
        byName[_normalize('Personal')] ?? byName[_normalize('Trabajadores')];
    final personalRuts = <String>{};
    if (personalSheet != null) {
      final header = _findHeaderRow(
        personalSheet.rows,
        requiredAliases: const [
          ['rut'],
          ['nombre completo', 'nombres', 'nombre'],
        ],
      );
      if (header != null) {
        final headers = _headersFromRow(personalSheet.rows[header]);
        final rutCol = _findColumn(headers, const ['rut']);
        if (rutCol != null) {
          for (var i = header + 1; i < personalSheet.rows.length; i++) {
            final rut = _normalizeRut(_valueAt(personalSheet.rows[i], rutCol));
            if (rut.isNotEmpty) personalRuts.add(rut);
          }
        }
      }
    }

    final summaries = <OperationSheetSummary>[];
    final warnings = <String>[];
    for (final expectedName in expected) {
      final sheet =
          byName[_normalize(expectedName)] ??
          (expectedName == 'Personal'
              ? byName[_normalize('Trabajadores')]
              : null);
      if (sheet == null) {
        summaries.add(
          OperationSheetSummary(name: expectedName, found: false, rows: 0),
        );
        if (expectedName == 'Control' || expectedName == 'Personal') {
          warnings.add('No se encontró la hoja obligatoria $expectedName.');
        }
        continue;
      }

      if (expectedName == 'Control') {
        summaries.add(
          OperationSheetSummary(
            name: expectedName,
            found: true,
            rows: _countNonEmptyRows(sheet.rows),
          ),
        );
        continue;
      }

      final header = _findHeaderRow(
        sheet.rows,
        requiredAliases:
            expectedName == 'Proveedores' || expectedName == 'Vehículos'
            ? const <List<String>>[]
            : const [
                ['rut'],
              ],
      );
      if (header == null) {
        summaries.add(
          OperationSheetSummary(
            name: expectedName,
            found: true,
            rows: 0,
            invalidRows: 1,
          ),
        );
        warnings.add(
          'La hoja $expectedName no tiene encabezados reconocibles.',
        );
        continue;
      }
      final headers = _headersFromRow(sheet.rows[header]);
      final rutCol = _findColumn(headers, const ['rut']);
      var count = 0;
      var invalid = 0;
      var orphan = 0;
      for (var i = header + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.every((cell) => cell.trim().isEmpty)) continue;
        count++;
        if (rutCol != null) {
          final rut = _valueAt(row, rutCol);
          if (rut.isEmpty || !_isValidRut(rut)) {
            invalid++;
          } else if (expectedName != 'Personal' &&
              personalRuts.isNotEmpty &&
              !personalRuts.contains(_normalizeRut(rut))) {
            orphan++;
          }
        }
      }
      summaries.add(
        OperationSheetSummary(
          name: expectedName,
          found: true,
          rows: count,
          invalidRows: invalid,
          orphanRutRows: orphan,
        ),
      );
      if (orphan > 0) {
        warnings.add(
          '$expectedName: $orphan registro(s) con RUT no presente en Personal.',
        );
      }
    }

    return OperationImportOverview(
      sheets: summaries,
      control: _readControl(byName[_normalize('Control')]),
      warnings: warnings,
    );
  }

  static Map<String, String> _readControl(_XlsxSheet? sheet) {
    if (sheet == null) return const {};
    final values = <String, String>{};
    for (final row in sheet.rows) {
      if (row.length < 2) continue;
      final key = row[0].trim();
      final value = row[1].trim();
      if (key.isNotEmpty && value.isNotEmpty && _normalize(key) != 'campo') {
        values[key] = value;
      }
    }
    return values;
  }

  static int _countNonEmptyRows(List<List<String>> rows) =>
      rows.where((row) => row.any((cell) => cell.trim().isNotEmpty)).length;

  static int? _findHeaderRow(
    List<List<String>> rows, {
    required List<List<String>> requiredAliases,
  }) {
    for (var index = 0; index < rows.length && index < 20; index++) {
      final headers = _headersFromRow(rows[index]);
      if (headers.isEmpty) continue;
      final matches = requiredAliases.every(
        (aliases) => _findColumn(headers, aliases) != null,
      );
      if (matches) return index;
      if (requiredAliases.isEmpty && headers.length >= 2) return index;
    }
    return null;
  }

  static Map<String, int> _headersFromRow(List<String> row) {
    final headers = <String, int>{};
    for (var column = 0; column < row.length; column++) {
      final value = row[column].trim();
      if (value.isNotEmpty) headers[_normalize(value)] = column;
    }
    return headers;
  }

  static (String, String) _splitName(String fullName, String explicitLastName) {
    if (explicitLastName.trim().isNotEmpty) {
      return (fullName.trim(), explicitLastName.trim());
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return (fullName.trim(), '');
    return (parts.first, parts.skip(1).join(' '));
  }

  static List<_XlsxSheet> _readXlsxWithoutStyles(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final files = <String, ArchiveFile>{
        for (final file in archive.files)
          if (file.isFile) _normalizeZipPath(file.name): file,
      };

      String readText(String path) {
        final file = files[_normalizeZipPath(path)];
        if (file == null) {
          throw FormatException('Falta el componente interno $path.');
        }
        final content = file.content;
        final data = content;
        return utf8.decode(data, allowMalformed: true);
      }

      final workbook = XmlDocument.parse(readText('xl/workbook.xml'));
      final relationships = XmlDocument.parse(
        readText('xl/_rels/workbook.xml.rels'),
      );
      final relationshipTargets = <String, String>{};
      for (final node in relationships.descendants.whereType<XmlElement>()) {
        if (node.name.local != 'Relationship') continue;
        final id = node.getAttribute('Id');
        final target = node.getAttribute('Target');
        if (id != null && target != null) relationshipTargets[id] = target;
      }

      final sharedStrings = <String>[];
      if (files.containsKey('xl/sharedStrings.xml')) {
        final shared = XmlDocument.parse(readText('xl/sharedStrings.xml'));
        for (final item in shared.descendants.whereType<XmlElement>().where(
          (e) => e.name.local == 'si',
        )) {
          sharedStrings.add(
            item.descendants
                .whereType<XmlElement>()
                .where((e) => e.name.local == 't')
                .map((e) => e.innerText)
                .join(),
          );
        }
      }

      final result = <_XlsxSheet>[];
      for (final sheet in workbook.descendants.whereType<XmlElement>().where(
        (e) => e.name.local == 'sheet',
      )) {
        final name = sheet.getAttribute('name') ?? 'Hoja';
        String? relationId;
        for (final attribute in sheet.attributes) {
          if (attribute.name.local == 'id') {
            relationId = attribute.value;
            break;
          }
        }
        if (relationId == null) continue;
        final target = relationshipTargets[relationId];
        if (target == null) continue;
        final sheetPath = _resolveWorkbookTarget(target);
        final xml = XmlDocument.parse(readText(sheetPath));
        result.add(_XlsxSheet(name, _parseSheetRows(xml, sharedStrings)));
      }
      return result;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'No se pudo abrir el archivo .xlsx en modo seguro. Detalle: $error',
      );
    }
  }

  static List<List<String>> _parseSheetRows(
    XmlDocument document,
    List<String> sharedStrings,
  ) {
    final rows = <List<String>>[];
    for (final rowElement in document.descendants.whereType<XmlElement>().where(
      (e) => e.name.local == 'row',
    )) {
      final values = <int, String>{};
      var maxColumn = -1;
      var sequentialColumn = 0;
      for (final cell in rowElement.children.whereType<XmlElement>().where(
        (e) => e.name.local == 'c',
      )) {
        final reference = cell.getAttribute('r');
        final column = reference == null
            ? sequentialColumn
            : _columnIndex(reference);
        sequentialColumn = column + 1;
        maxColumn = column > maxColumn ? column : maxColumn;
        values[column] = _readCellValue(cell, sharedStrings);
      }
      if (maxColumn < 0) {
        rows.add(const <String>[]);
      } else {
        rows.add(
          List<String>.generate(maxColumn + 1, (index) => values[index] ?? ''),
        );
      }
    }
    return rows;
  }

  static String _readCellValue(XmlElement cell, List<String> sharedStrings) {
    final type = cell.getAttribute('t');
    if (type == 'inlineStr') {
      return cell.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 't')
          .map((e) => e.innerText)
          .join()
          .trim();
    }
    final valueElement = cell.descendants.whereType<XmlElement>().firstWhere(
      (e) => e.name.local == 'v',
      orElse: () => XmlElement(XmlName('v')),
    );
    final raw = valueElement.innerText.trim();
    if (type == 's') {
      final index = int.tryParse(raw);
      return index != null && index >= 0 && index < sharedStrings.length
          ? sharedStrings[index].trim()
          : '';
    }
    if (type == 'b') return raw == '1' ? 'Sí' : 'No';
    return raw;
  }

  static int _columnIndex(String reference) {
    final letters = RegExp(r'^[A-Za-z]+').stringMatch(reference) ?? 'A';
    var result = 0;
    for (final code in letters.toUpperCase().codeUnits) {
      result = result * 26 + (code - 64);
    }
    return result - 1;
  }

  static String _resolveWorkbookTarget(String target) {
    final normalized = target.replaceAll('\\', '/');
    if (normalized.startsWith('/')) return normalized.substring(1);
    if (normalized.startsWith('xl/')) return normalized;
    final parts = <String>['xl'];
    for (final part in normalized.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    return parts.join('/');
  }

  static String _normalizeZipPath(String path) =>
      path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');

  static int? _findColumn(Map<String, int> headers, List<String> alternatives) {
    for (final alternative in alternatives) {
      final value = headers[_normalize(alternative)];
      if (value != null) return value;
    }
    return null;
  }

  static String _valueByHeaders(
    List<String> row,
    Map<String, int> headers,
    List<String> alternatives, {
    String fallback = '',
  }) {
    final column = _findColumn(headers, alternatives);
    if (column == null) return fallback;
    final value = _valueAt(row, column);
    return value.isEmpty ? fallback : value;
  }

  static String _valueAt(List<String> row, int column) {
    if (column < 0 || column >= row.length) return '';
    return row[column].trim();
  }

  static WorkerStatus _parseStatus(String text) {
    final normalized = _normalize(text);
    if (normalized.contains('pasaje')) return WorkerStatus.ticketIssued;
    if (normalized.contains('viaje')) return WorkerStatus.traveling;
    if (normalized.contains('aloj')) return WorkerStatus.lodging;
    if (normalized.contains('traslado')) return WorkerStatus.transfer;
    if (normalized.contains('faena')) return WorkerStatus.atSite;
    if (normalized.contains('final')) return WorkerStatus.finished;
    if (normalized.contains('cancel')) return WorkerStatus.cancelled;
    return WorkerStatus.pending;
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  static bool _isValidRut(String value) {
    final normalized = _normalizeRut(value).toUpperCase();
    if (normalized.length < 2) return false;
    final body = normalized.substring(0, normalized.length - 1);
    final suppliedDv = normalized.substring(normalized.length - 1);
    if (!RegExp(r'^\d+$').hasMatch(body)) return false;

    var sum = 0;
    var multiplier = 2;
    for (var index = body.length - 1; index >= 0; index--) {
      sum += int.parse(body[index]) * multiplier;
      multiplier = multiplier == 7 ? 2 : multiplier + 1;
    }
    final result = 11 - (sum % 11);
    final expectedDv = result == 11 ? '0' : (result == 10 ? 'K' : '$result');
    return suppliedDv == expectedDv;
  }

  static String normalizeRut(String value) => _normalizeRut(value);

  static String _normalizeRut(String value) {
    return value.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
