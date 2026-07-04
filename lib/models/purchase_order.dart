enum PurchaseOrderStatus { pending, partiallyReceived, received }

extension PurchaseOrderStatusLabel on PurchaseOrderStatus {
  String get label {
    switch (this) {
      case PurchaseOrderStatus.pending:
        return 'En attente';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Reçu partiellement';
      case PurchaseOrderStatus.received:
        return 'Reçu complètement';
    }
  }
}

class PurchaseOrderItem {
  final int? id;
  final int? orderId;
  final int productId;
  final String productName;
  final int quantityOrdered;
  final int quantityReceived;
  final double unitPrice;

  PurchaseOrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.quantityOrdered,
    this.quantityReceived = 0,
    required this.unitPrice,
  });

  int get remaining => quantityOrdered - quantityReceived;
  double get total => quantityOrdered * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'quantityOrdered': quantityOrdered,
      'quantityReceived': quantityReceived,
      'unitPrice': unitPrice,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'],
      orderId: map['orderId'],
      productId: map['productId'],
      productName: map['productName'],
      quantityOrdered: map['quantityOrdered'],
      quantityReceived: map['quantityReceived'] ?? 0,
      unitPrice: (map['unitPrice'] as num).toDouble(),
    );
  }
}

class PurchaseOrder {
  final int? id;
  final int supplierId;
  final String supplierName;
  final DateTime date;
  final PurchaseOrderStatus status;

  PurchaseOrder({
    this.id,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    this.status = PurchaseOrderStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'date': date.toIso8601String(),
      'status': status.name,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'],
      supplierId: map['supplierId'],
      supplierName: map['supplierName'],
      date: DateTime.parse(map['date']),
      status: PurchaseOrderStatus.values
          .firstWhere((s) => s.name == map['status'],
              orElse: () => PurchaseOrderStatus.pending),
    );
  }
}
