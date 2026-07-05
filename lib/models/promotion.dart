enum DiscountType { percentage, fixedAmount }
enum PromotionScope { product, category, cart }

extension DiscountTypeLabel on DiscountType {
  String get label =>
      this == DiscountType.percentage ? 'Pourcentage (%)' : 'Montant fixe (HTG)';
}

extension PromotionScopeLabel on PromotionScope {
  String get label {
    switch (this) {
      case PromotionScope.product:
        return 'Un produit précis';
      case PromotionScope.category:
        return 'Une catégorie entière';
      case PromotionScope.cart:
        return 'Code promo (panier entier)';
    }
  }
}

class Promotion {
  final int? id;
  final String name;
  final DiscountType discountType;
  final double discountValue;
  final PromotionScope scope;
  final int? targetProductId;
  final String? targetProductName;
  final String? targetCategory;
  final String? promoCode;
  final DateTime startDate;
  final DateTime endDate;

  Promotion({
    this.id,
    required this.name,
    required this.discountType,
    required this.discountValue,
    required this.scope,
    this.targetProductId,
    this.targetProductName,
    this.targetCategory,
    this.promoCode,
    required this.startDate,
    required this.endDate,
  });

  bool isActiveOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  double applyTo(double price) {
    final discounted = discountType == DiscountType.percentage
        ? price - (price * discountValue / 100)
        : price - discountValue;
    return discounted < 0 ? 0 : discounted;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'scope': scope.name,
      'targetProductId': targetProductId,
      'targetProductName': targetProductName,
      'targetCategory': targetCategory,
      'promoCode': promoCode,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'],
      name: map['name'],
      discountType: DiscountType.values
          .firstWhere((t) => t.name == map['discountType']),
      discountValue: (map['discountValue'] as num).toDouble(),
      scope: PromotionScope.values.firstWhere((s) => s.name == map['scope']),
      targetProductId: map['targetProductId'],
      targetProductName: map['targetProductName'],
      targetCategory: map['targetCategory'],
      promoCode: map['promoCode'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
}
