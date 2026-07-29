import '../../hotels/data/hotel_repository.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../transfers/data/transfer_repository.dart';
import '../domain/worker.dart';

enum LogisticsReadinessLevel { critical, incomplete, advanced, ready }

class LogisticsReadiness {
  final int percentage;
  final LogisticsReadinessLevel level;
  final bool hasTicket;
  final bool hasHotel;
  final bool hasTransfer;

  const LogisticsReadiness({
    required this.percentage,
    required this.level,
    required this.hasTicket,
    required this.hasHotel,
    required this.hasTransfer,
  });

  String get label {
    switch (level) {
      case LogisticsReadinessLevel.ready:
        return 'Logística lista';
      case LogisticsReadinessLevel.advanced:
        return 'Preparación avanzada';
      case LogisticsReadinessLevel.incomplete:
        return 'Logística incompleta';
      case LogisticsReadinessLevel.critical:
        return 'Preparación crítica';
    }
  }

  List<String> get missingServices {
    final values = <String>[];
    if (!hasTicket) values.add('pasaje');
    if (!hasHotel) values.add('hotel');
    if (!hasTransfer) values.add('traslado');
    return values;
  }
}

class LogisticsReadinessService {
  const LogisticsReadinessService._();

  static LogisticsReadiness evaluate(Worker worker) {
    final ticket = InMemoryTicketRepository.instance.findByWorkerId(worker.id);
    final hotel = InMemoryHotelRepository.instance.findByWorkerId(worker.id);
    final transfers = InMemoryTransferRepository.instance.findByWorkerId(
      worker.id,
    );

    final hasTicket = ticket != null || worker.ticket.trim().isNotEmpty;
    final hasHotel = hotel != null || worker.hotel.trim().isNotEmpty;
    final hasTransfer =
        transfers.isNotEmpty || worker.transfer.trim().isNotEmpty;
    final completed = [
      hasTicket,
      hasHotel,
      hasTransfer,
    ].where((value) => value).length;
    final percentage = ((completed / 3) * 100).round();

    final level = switch (completed) {
      3 => LogisticsReadinessLevel.ready,
      2 => LogisticsReadinessLevel.advanced,
      1 => LogisticsReadinessLevel.incomplete,
      _ => LogisticsReadinessLevel.critical,
    };

    return LogisticsReadiness(
      percentage: percentage,
      level: level,
      hasTicket: hasTicket,
      hasHotel: hasHotel,
      hasTransfer: hasTransfer,
    );
  }
}
