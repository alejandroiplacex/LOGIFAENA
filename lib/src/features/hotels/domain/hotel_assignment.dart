enum HotelStatus { requested, confirmed, checkedIn, checkedOut, cancelled }

extension HotelStatusLabel on HotelStatus {
  String get label {
    switch (this) {
      case HotelStatus.requested: return 'Solicitado';
      case HotelStatus.confirmed: return 'Confirmado';
      case HotelStatus.checkedIn: return 'Check-in realizado';
      case HotelStatus.checkedOut: return 'Check-out realizado';
      case HotelStatus.cancelled: return 'Cancelado';
    }
  }
}

class HotelAssignment {
  final String id;
  String workerId;
  String hotelName;
  String city;
  String address;
  String contactName;
  String contactPhone;
  String room;
  DateTime checkInDate;
  DateTime checkOutDate;
  double dailyRate;
  String confirmationCode;
  String notes;
  HotelStatus status;

  HotelAssignment({
    required this.id,
    required this.workerId,
    required this.hotelName,
    required this.city,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.dailyRate,
    required this.confirmationCode,
    required this.notes,
    required this.status,
  });

  int get nights {
    final value = checkOutDate.difference(checkInDate).inDays;
    return value <= 0 ? 1 : value;
  }

  double get totalCost => nights * dailyRate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'hotelName': hotelName,
        'city': city,
        'address': address,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'room': room,
        'checkInDate': checkInDate.toIso8601String(),
        'checkOutDate': checkOutDate.toIso8601String(),
        'dailyRate': dailyRate,
        'confirmationCode': confirmationCode,
        'notes': notes,
        'status': status.name,
      };

  factory HotelAssignment.fromJson(Map<String, dynamic> json) => HotelAssignment(
        id: json['id'] as String,
        workerId: json['workerId'] as String? ?? '',
        hotelName: json['hotelName'] as String? ?? '',
        city: json['city'] as String? ?? '',
        address: json['address'] as String? ?? '',
        contactName: json['contactName'] as String? ?? '',
        contactPhone: json['contactPhone'] as String? ?? '',
        room: json['room'] as String? ?? '',
        checkInDate: DateTime.tryParse(json['checkInDate'] as String? ?? '') ?? DateTime.now(),
        checkOutDate: DateTime.tryParse(json['checkOutDate'] as String? ?? '') ?? DateTime.now(),
        dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0,
        confirmationCode: json['confirmationCode'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        status: HotelStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => HotelStatus.requested,
        ),
      );
}

