import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, SaleItem> _items = {};
  String _currency = 'HTG';

  List<SaleItem> get items => _items.values.toList();
  double get total => _items.values.fold(0, (sum, item) => sum + item.total);
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  String get currency => _currency;

  void addProduct(Product product) {
    final unitPrice = product.priceFor(_currency);
    if (_items.containsKey(product.id)) {
      final existing = _items[product.id]!;
      _items[product.id!] = SaleItem(
        productId: product.id!,
        productName: product.name,
        unitPrice: unitPrice,
        quantity: existing.quantity + 1,
      );
    } else {
      _items[product.id!] = SaleItem(
        productId: product.id!,
        productName: product.name,
        unitPrice: unitPrice,
        quantity: 1,
      );
    }
    notifyListeners();
  }

  void decreaseQuantity(int productId) {
    if (!_items.containsKey(productId)) return;
    final existing = _items[productId]!;
    if (existing.quantity <= 1) {
      _items.remove(productId);
    } else {
      _items[productId] = SaleItem(
        productId: existing.productId,
        productName: existing.productName,
        unitPrice: existing.unitPrice,
        quantity: existing.quantity - 1,
      );
    }
    notifyListeners();
  }

  void removeProduct(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Change la devise active et recalcule le prix unitaire de chaque
  /// article du panier à partir de la liste de produits fournie.
  void switchCurrency(String newCurrency, List<Product> products) {
    if (newCurrency == _currency) return;
    _currency = newCurrency;
    final updated = <int, SaleItem>{};
    for (final entry in _items.entries) {
      final product = products.where((p) => p.id == entry.key);
      if (product.isEmpty) {
        updated[entry.key] = entry.value;
        continue;
      }
      updated[entry.key] = SaleItem(
        productId: entry.value.productId,
        productName: entry.value.productName,
        unitPrice: product.first.priceFor(newCurrency),
        quantity: entry.value.quantity,
      );
    }
    _items
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }
}
