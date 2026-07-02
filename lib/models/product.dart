class Product {
  final int? id;
  final String name;
  final String barcode;
  final String category;
  final double purchasePrice;
  final double sellPrice;
  final double purchasePriceUSD;
  final double sellPriceUSD;
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
    this.purchasePriceUSD = 0,
    this.sellPriceUSD = 0,
    required this.stockQuantity,
    this.lowStockThreshold = 5,
    this.expiryDate,
  });

  double get margin => sellPrice - purchasePrice;
  double get marginUSD => sellPriceUSD - purchasePriceUSD;
  bool get isLowStock => stockQuantity <= lowStockThreshold;

  double priceFor(String currency) =>
      currency == 'USD' ? sellPriceUSD : sellPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'purchasePriceUSD': purchasePriceUSD,
      'sellPriceUSD': sellPriceUSD,
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
      purchasePriceUSD: (map['purchasePriceUSD'] ?? 0).toDouble(),
      sellPriceUSD: (map['sellPriceUSD'] ?? 0).toDouble(),
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
      purchasePriceUSD: purchasePriceUSD,
      sellPriceUSD: sellPriceUSD,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold,
      expiryDate: expiryDate,
    );
  }
}
