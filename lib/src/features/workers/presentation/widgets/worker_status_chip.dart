import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/worker.dart';

class WorkerStatusChip extends StatelessWidget {
  final WorkerStatus status;

  const WorkerStatusChip({super.key, required this.status});

  Color get color {
    switch (status) {
      case WorkerStatus.pending:
        return Colors.grey;
      case WorkerStatus.ticketIssued:
        return AppColors.warning;
      case WorkerStatus.traveling:
        return Colors.deepOrange;
      case WorkerStatus.lodging:
        return Colors.blue;
      case WorkerStatus.transfer:
        return Colors.orange;
      case WorkerStatus.atSite:
        return AppColors.success;
      case WorkerStatus.finished:
        return Colors.blueGrey;
      case WorkerStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(radius: 5, backgroundColor: color),
      label: Text(status.label),
      backgroundColor: color.withOpacity(0.10),
      side: BorderSide(color: color.withOpacity(0.35)),
      visualDensity: VisualDensity.compact,
    );
  }
}
