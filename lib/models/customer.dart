class Customer {
  final int? id;
  final String name;
  final String phone;
  final int loyaltyPoints;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.loyaltyPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'loyaltyPoints': loyaltyPoints,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
    );
  }

  Customer copyWith({int? loyaltyPoints}) {
    return Customer(
      id: id,
      name: name,
      phone: phone,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }
}
