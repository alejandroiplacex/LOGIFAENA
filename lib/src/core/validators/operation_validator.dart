import '../models/operation.dart';

class OperationValidationResult {
  final List<String> errors;
  final List<String> warnings;

  const OperationValidationResult({
    required this.errors,
    required this.warnings,
  });

  bool get isValid => errors.isEmpty;
}

class OperationValidator {
  const OperationValidator();

  OperationValidationResult validate(Operation operation) {
    final errors = <String>[];
    final warnings = <String>[];

    if (operation.company.trim().isEmpty) {
      errors.add('La empresa es obligatoria.');
    }
    if (operation.project.trim().isEmpty) {
      errors.add('El proyecto es obligatorio.');
    }
    if (operation.endDate.isBefore(operation.startDate)) {
      errors.add('La fecha de término no puede ser anterior al inicio.');
    }
    if (operation.workers.isEmpty) {
      warnings.add('La operación no contiene trabajadores.');
    }

    final seenRuts = <String>{};
    for (final worker in operation.workers) {
      final normalizedRut = Operation.normalizeRut(worker.rut);
      if (normalizedRut.isEmpty) {
        errors.add('Existe un trabajador sin RUT.');
      } else if (!seenRuts.add(normalizedRut)) {
        errors.add('RUT duplicado en la operación: ${worker.rut}.');
      }
    }

    return OperationValidationResult(errors: errors, warnings: warnings);
  }
}
