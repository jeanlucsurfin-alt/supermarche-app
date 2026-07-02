enum MovementType { entry, exit, adjustment }

class StockMovement {
  final int? id;
  final int productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final String? reason;
  final int? supplierId;
  final DateTime date;

  StockMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    this.reason,
    this.supplierId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'reason': reason,
      'supplierId': supplierId,
      'date': date.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      type: MovementType.values.firstWhere((t) => t.name == map['type']),
      quantity: map['quantity'],
      reason: map['reason'],
      supplierId: map['supplierId'],
      date: DateTime.parse(map['date']),
    );
  }
}
