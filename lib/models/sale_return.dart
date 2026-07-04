class ReturnItem {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  ReturnItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap(int returnId) {
    return {
      'returnId': returnId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class SaleReturn {
  final int? id;
  final int saleId;
  final DateTime date;
  final int employeeId;
  final String employeeName;
  final String? reason;
  final List<ReturnItem> items;

  SaleReturn({
    this.id,
    required this.saleId,
    required this.date,
    required this.employeeId,
    required this.employeeName,
    this.reason,
    required this.items,
  });

  double get totalRefunded => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'date': date.toIso8601String(),
      'employeeId': employeeId,
      'employeeName': employeeName,
      'reason': reason,
      'totalRefunded': totalRefunded,
    };
  }
}
