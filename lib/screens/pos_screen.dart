import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/promotion.dart';
import '../providers/cart_provider.dart';
import '../providers/category_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/fafoutt_logo.dart';
import '../widgets/logout_button.dart';
import 'barcode_scanner_screen.dart';
import 'categories_screen.dart';
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
  final Map<int, Promotion> _activePromotions = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _db.getAllProducts();
    final promotions = <int, Promotion>{};
    for (final product in products) {
      final promo =
          await _db.getActivePromotionForProduct(product.id!, product.category);
      if (promo != null) promotions[product.id!] = promo;
    }
    setState(() {
      _products = products;
      _activePromotions
        ..clear()
        ..addAll(promotions);
      _applyFilters();
    });
  }

  double _priceFor(Product product) {
    final base = product.priceFor(context.read<CartProvider>().currency);
    final promo = _activePromotions[product.id];
    if (promo == null) return base;
    // Les promotions par pourcentage s'appliquent quelle que soit la
    // devise ; les montants fixes sont exprimés en HTG (limitation connue
    // en devise USD).
    if (promo.discountType == DiscountType.percentage) {
      return promo.applyTo(base);
    }
    return context.read<CartProvider>().currency == 'HTG'
        ? promo.applyTo(base)
        : base;
  }

  List<String> get _categories {
    final providerNames = context.read<CategoryProvider>().names;
    return ['Tout', ...providerNames];
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
    context
        .read<CartProvider>()
        .addProduct(product, unitPriceOverride: _priceFor(product));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const FafouttHeader(subtitle: 'Point de Vente'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                final next = cart.currency == 'HTG' ? 'USD' : 'HTG';
                context.read<CartProvider>().switchCurrency(next, _products);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_exchange_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(cart.currency,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Gérer les catégories',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanner un code-barres',
            onPressed: _scanBarcode,
          ),
          const LogoutButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          final productColumn = Column(
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
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final width = gridConstraints.maxWidth;
                          final crossAxisCount = width > 900
                              ? 5
                              : width > 650
                                  ? 4
                                  : width > 420
                                      ? 3
                                      : 2;
                          return GridView.builder(
                            padding:
                                EdgeInsets.fromLTRB(16, 0, 16, isWide ? 16 : 90),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return _ProductCard(
                                product: product,
                                currency: cart.currency,
                                promotion: _activePromotions[product.id],
                                onTap: () => context.read<CartProvider>().addProduct(
                                    product,
                                    unitPriceOverride: _priceFor(product)),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 3, child: productColumn),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(left: BorderSide(color: Color(0xFFEBEDF2))),
                    ),
                    child: _CartPanel(
                      currency: cart.currency,
                      products: _products,
                      onCheckoutDone: _loadProducts,
                    ),
                  ),
                ),
              ],
            );
          }

          // Téléphone : produits en plein écran + barre panier en bas
          return Stack(
            children: [
              productColumn,
              Align(
                alignment: Alignment.bottomCenter,
                child: _CartSummaryBar(
                  currency: cart.currency,
                  products: _products,
                  onCheckoutDone: _loadProducts,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Barre compacte en bas d'écran (téléphone) : ouvre le panier complet
/// en plein écran au tap.
class _CartSummaryBar extends StatelessWidget {
  final String currency;
  final List<Product> products;
  final VoidCallback onCheckoutDone;

  const _CartSummaryBar({
    required this.currency,
    required this.products,
    required this.onCheckoutDone,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.items.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: AppColors.navy,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3E6EC),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: _CartPanel(
                            currency: currency,
                            products: products,
                            onCheckoutDone: onCheckoutDone,
                            scrollController: scrollController,
                            closeOnCheckout: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${cart.itemCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Voir le panier',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const Spacer(),
                  Text(
                    formatPrice(cart.total, currency),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenu du panier, réutilisé en panneau latéral (tablette)
/// ou en tiroir plein écran (téléphone).
class _CartPanel extends StatelessWidget {
  final String currency;
  final List<Product> products;
  final VoidCallback onCheckoutDone;
  final ScrollController? scrollController;
  final bool closeOnCheckout;

  const _CartPanel({
    required this.currency,
    required this.products,
    required this.onCheckoutDone,
    this.scrollController,
    this.closeOnCheckout = false,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text('Panier',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(width: 8),
              if (cart.itemCount > 0)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
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
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 16, color: AppColors.textSecondary),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () => context
                                    .read<CartProvider>()
                                    .removeProduct(item.productId),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatPrice(item.unitPrice, currency),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              Row(
                                children: [
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
                                      final product = products.firstWhere(
                                          (p) => p.id == item.productId);
                                      context.read<CartProvider>().addProduct(
                                          product,
                                          unitPriceOverride: item.unitPrice);
                                    },
                                  ),
                                ],
                              ),
                            ],
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    formatPrice(cart.total, currency),
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
                  icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                  onPressed: cart.items.isEmpty
                      ? null
                      : () async {
                          if (closeOnCheckout) Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CheckoutScreen()),
                          );
                          onCheckoutDone();
                        },
                  label: const Text('PASSER AU PAIEMENT'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String currency;
  final Promotion? promotion;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.currency,
    this.promotion,
    required this.onTap,
  });

  double get _basePrice => product.priceFor(currency);

  double get _discountedPrice {
    if (promotion == null) return _basePrice;
    if (promotion!.discountType == DiscountType.percentage) {
      return promotion!.applyTo(_basePrice);
    }
    // Les remises en montant fixe sont exprimées en HTG.
    return currency == 'HTG' ? promotion!.applyTo(_basePrice) : _basePrice;
  }

  bool get _hasDiscount => promotion != null && _discountedPrice < _basePrice;

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final catColor = categoryProvider.colorFor(product.category);
    final catIcon = categoryProvider.iconFor(product.category);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(catIcon, color: catColor, size: 18),
                  ),
                  if (_hasDiscount) ...[
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('PROMO',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 9)),
                    ),
                  ],
                ],
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
              if (_hasDiscount)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatPrice(_basePrice, currency),
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatPrice(_discountedPrice, currency),
                  maxLines: 1,
                  style: TextStyle(
                    color: _hasDiscount ? AppColors.danger : AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
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
