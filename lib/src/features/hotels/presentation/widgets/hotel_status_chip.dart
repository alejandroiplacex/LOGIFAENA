import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/hotel_assignment.dart';

class HotelStatusChip extends StatelessWidget {
  final HotelStatus status;
  const HotelStatusChip({super.key, required this.status});

  Color get color {
    switch (status) {
      case HotelStatus.requested:
        return AppColors.warning;
      case HotelStatus.confirmed:
        return AppColors.success;
      case HotelStatus.checkedIn:
        return Colors.blue;
      case HotelStatus.checkedOut:
        return Colors.blueGrey;
      case HotelStatus.cancelled:
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
