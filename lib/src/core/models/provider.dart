class Provider {
  final String id;
  final String operationId;
  String name;
  String category;
  String contactName;
  String phone;
  String email;
  String address;
  String notes;
  bool active;
  final DateTime createdAt;
  DateTime updatedAt;
  String createdBy;

  Provider({
    required this.id,
    required this.operationId,
    required this.name,
    required this.category,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationId': operationId,
        'name': name,
        'category': category,
        'contactName': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory Provider.fromJson(Map<String, dynamic> json) => Provider(
        id: json['id'] as String? ?? '',
        operationId: json['operationId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        contactName: json['contactName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        createdBy: json['createdBy'] as String? ?? '',
      );
}
