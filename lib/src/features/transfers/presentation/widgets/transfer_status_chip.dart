import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/transfer.dart';

class TransferStatusChip extends StatelessWidget {
  final TransferStatus status;

  const TransferStatusChip({
    super.key,
    required this.status,
  });

  Color get color {
    switch (status) {
      case TransferStatus.scheduled:
        return AppColors.warning;
      case TransferStatus.boarding:
        return Colors.blue;
      case TransferStatus.onRoute:
        return Colors.deepOrange;
      case TransferStatus.completed:
        return AppColors.success;
      case TransferStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        radius: 5,
        backgroundColor: color,
      ),
      label: Text(status.label),
      backgroundColor: color.withOpacity(0.10),
      side: BorderSide(color: color.withOpacity(0.35)),
      visualDensity: VisualDensity.compact,
    );
  }
}
