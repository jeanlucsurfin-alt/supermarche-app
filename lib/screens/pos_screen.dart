import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';
import 'barcode_scanner_screen.dart';
import 'checkout_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'Tout';
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _db.getAllProducts();
    setState(() {
      _products = products;
      _applyFilters();
    });
  }

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList()..sort();
    return ['Tout', ...cats];
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        final matchesQuery = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.barcode.contains(query);
        final matchesCategory =
            _selectedCategory == 'Tout' || p.category == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null) return;

    final product = await _db.getProductByBarcode(barcode);
    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produit introuvable pour ce code-barres'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (!mounted) return;
    context.read<CartProvider>().addProduct(product);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const FafouttHeader(subtitle: 'Point de Vente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanner un code-barres',
            onPressed: _scanBarcode,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          // Colonne produits
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit ou un code...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final selected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat);
                          _applyFilters();
                        },
                        selectedColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected
                                ? AppColors.navy
                                : const Color(0xFFE3E6EC),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 40, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text('Aucun produit trouvé',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.15,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _ProductCard(
                              product: product,
                              currencyFormat: _currencyFormat,
                              onTap: () =>
                                  context.read<CartProvider>().addProduct(product),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Panier
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFEBEDF2))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            color: AppColors.navy, size: 20),
                        const SizedBox(width: 8),
                        Text('Panier',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        if (cart.itemCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${cart.itemCount} article${cart.itemCount > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cart.items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shopping_cart_outlined,
                                    size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text(
                                  'Le panier est vide\nTouchez un produit pour l\'ajouter',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: cart.items.length,
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.productName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          Text(
                                            _currencyFormat
                                                .format(item.unitPrice),
                                            style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _QtyButton(
                                      icon: Icons.remove_rounded,
                                      onTap: () => context
                                          .read<CartProvider>()
                                          .decreaseQuantity(item.productId),
                                    ),
                                    SizedBox(
                                      width: 28,
                                      child: Text('${item.quantity}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    _QtyButton(
                                      icon: Icons.add_rounded,
                                      onTap: () {
                                        final product = _products.firstWhere(
                                            (p) => p.id == item.productId);
                                        context
                                            .read<CartProvider>()
                                            .addProduct(product);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      border: Border(top: BorderSide(color: Color(0xFFEBEDF2))),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              _currencyFormat.format(cart.total),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.point_of_sale_rounded,
                                size: 18),
                            onPressed: cart.items.isEmpty
                                ? null
                                : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const CheckoutScreen()),
                                    );
                                    _loadProducts();
                                  },
                            label: const Text('PASSER AU PAIEMENT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.inventory_2_rounded,
                    color: AppColors.navy, size: 18),
              ),
              const Spacer(),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12.5, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(product.sellPrice),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (product.isLowStock)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: AppColors.danger, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text('Stock bas',
                          style:
                              TextStyle(color: AppColors.danger, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE3E6EC)),
        ),
        child: Icon(icon, size: 15, color: AppColors.navy),
      ),
    );
  }
}
