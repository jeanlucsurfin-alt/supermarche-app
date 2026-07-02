class Supplier {
  final int? id;
  final String name;
  final String phone;
  final String? address;

  Supplier({
    this.id,
    required this.name,
    required this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
    );
  }
}
