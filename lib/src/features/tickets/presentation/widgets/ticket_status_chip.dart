import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/ticket.dart';

class TicketStatusChip extends StatelessWidget {
  final TicketStatus status;

  const TicketStatusChip({super.key, required this.status});

  Color get color {
    switch (status) {
      case TicketStatus.requested:
        return AppColors.warning;
      case TicketStatus.issued:
        return AppColors.success;
      case TicketStatus.rescheduled:
        return Colors.deepOrange;
      case TicketStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(radius: 5, backgroundColor: color),
      label: Text(status.label),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
    );
  }
}
