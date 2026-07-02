import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, SaleItem> _items = {};

  List<SaleItem> get items => _items.values.toList();
  double get total => _items.values.fold(0, (sum, item) => sum + item.total);
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  void addProduct(Product product) {
    if (_items.containsKey(product.id)) {
      final existing = _items[product.id]!;
      _items[product.id!] = SaleItem(
        productId: product.id!,
        productName: product.name,
        unitPrice: product.sellPrice,
        quantity: existing.quantity + 1,
      );
    } else {
      _items[product.id!] = SaleItem(
        productId: product.id!,
        productName: product.name,
        unitPrice: product.sellPrice,
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
}
