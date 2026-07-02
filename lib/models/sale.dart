class SaleItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toMap(int saleId) {
    return {
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }
}

enum PaymentMethod { cash, card, mobileMoney, credit }

class Sale {
  final int? id;
  final DateTime date;
  final List<SaleItem> items;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final String? cashierName;
  final int? customerId;
  final String currency;

  Sale({
    this.id,
    required this.date,
    required this.items,
    required this.paymentMethod,
    required this.amountPaid,
    this.cashierName,
    this.customerId,
    this.currency = 'HTG',
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);
  double get change => amountPaid - total;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'amountPaid': amountPaid,
      'total': total,
      'cashierName': cashierName,
      'customerId': customerId,
      'currency': currency,
    };
  }
}
