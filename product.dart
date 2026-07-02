class Product {
  final int? id;
  final String name;
  final String barcode;
  final String category;
  final double purchasePrice;
  final double sellPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final DateTime? expiryDate;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.purchasePrice,
    required this.sellPrice,
    required this.stockQuantity,
    this.lowStockThreshold = 5,
    this.expiryDate,
  });

  double get margin => sellPrice - purchasePrice;
  bool get isLowStock => stockQuantity <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      category: map['category'],
      purchasePrice: map['purchasePrice'],
      sellPrice: map['sellPrice'],
      stockQuantity: map['stockQuantity'],
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
    );
  }

  Product copyWith({int? stockQuantity}) {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      category: category,
      purchasePrice: purchasePrice,
      sellPrice: sellPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold,
      expiryDate: expiryDate,
    );
  }
}
