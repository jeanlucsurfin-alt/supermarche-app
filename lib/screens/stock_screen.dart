import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/supplier.dart';
import '../providers/category_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';
import 'categories_screen.dart';
import 'employees_screen.dart';
import 'products_screen.dart';
import 'suppliers_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _lowStockOnly = false;
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await _db.getAllProducts();
    setState(() {
      _products = products;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final matchesQuery = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.barcode.contains(query);
        final matchesLowStock = !_lowStockOnly || p.isLowStock;
        return matchesQuery && matchesLowStock;
      }).toList();
    });
  }

  int get _lowStockCount => _products.where((p) => p.isLowStock).length;

  Future<void> _openMovementSheet(Product product) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MovementSheet(product: product, db: _db),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FafouttHeader(subtitle: 'Gestion des stocks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Gestion',
            onSelected: (value) async {
              Widget? screen;
              switch (value) {
                case 'produits':
                  screen = const ProductsScreen();
                  break;
                case 'categories':
                  screen = const CategoriesScreen();
                  break;
                case 'fournisseurs':
                  screen = const SuppliersScreen();
                  break;
                case 'employes':
                  screen = const EmployeesScreen();
                  break;
              }
              if (screen != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => screen!),
                );
                if (mounted) {
                  _load();
                  setState(() {});
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'produits',
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Produits'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Catégories'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'fournisseurs',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Fournisseurs'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'employes',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Employés'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
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
              onChanged: (_) => _applyFilter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Stock bas ($_lowStockCount)'),
                  selected: _lowStockOnly,
                  onSelected: (v) {
                    setState(() => _lowStockOnly = v);
                    _applyFilter();
                  },
                  avatar: Icon(Icons.warning_amber_rounded,
                      size: 16,
                      color: _lowStockOnly ? Colors.white : AppColors.danger),
                  selectedColor: AppColors.danger,
                  labelStyle: TextStyle(
                    color: _lowStockOnly ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _lowStockOnly
                          ? AppColors.danger
                          : const Color(0xFFE3E6EC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('Aucun produit trouvé',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final product = _filtered[index];
                      return _StockTile(
                        product: product,
                        currencyFormat: _currencyFormat,
                        onTap: () => _openMovementSheet(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _StockTile({
    required this.product,
    required this.currencyFormat,
    required this.onTap,
  });

  String? _expiryLabel() {
    if (product.expiryDate == null) return null;
    final days = product.expiryDate!.difference(DateTime.now()).inDays;
    if (days < 0) return 'Périmé';
    if (days == 0) return 'Expire aujourd\'hui';
    return 'Expire dans $days j';
  }

  @override
  Widget build(BuildContext context) {
    final expiry = _expiryLabel();
    final categoryProvider = context.watch<CategoryProvider>();
    final catColor = categoryProvider.colorFor(product.category);
    final catIcon = categoryProvider.iconFor(product.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${product.category} · ${currencyFormat.format(product.sellPrice).replaceAll(' ', '\u00A0')}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    if (expiry != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          expiry,
                          style: TextStyle(
                            color: expiry == 'Périmé'
                                ? AppColors.danger
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: product.isLowStock
                          ? AppColors.danger.withOpacity(0.12)
                          : AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${product.stockQuantity} en stock',
                      style: TextStyle(
                        color: product.isLowStock
                            ? AppColors.danger
                            : AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementSheet extends StatefulWidget {
  final Product product;
  final DatabaseService db;
  const _MovementSheet({required this.product, required this.db});

  @override
  State<_MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends State<_MovementSheet> {
  MovementType _type = MovementType.entry;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  List<Supplier> _suppliers = [];
  int? _selectedSupplierId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.db.getAllSuppliers().then((s) => setState(() => _suppliers = s));
  }

  Future<void> _save() async {
    final qty = int.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) return;

    setState(() => _saving = true);
    await widget.db.recordMovement(StockMovement(
      productId: widget.product.id!,
      productName: widget.product.name,
      type: _type,
      quantity: qty,
      reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      supplierId: _type == MovementType.entry ? _selectedSupplierId : null,
      date: DateTime.now(),
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E6EC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(widget.product.name,
                style: Theme.of(context).textTheme.titleLarge),
            Text('Stock actuel : ${widget.product.stockQuantity}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                    value: MovementType.entry,
                    label: Text('Entrée'),
                    icon: Icon(Icons.add_box_rounded, size: 16)),
                ButtonSegment(
                    value: MovementType.exit,
                    label: Text('Sortie'),
                    icon: Icon(Icons.remove_circle_outline, size: 16)),
                ButtonSegment(
                    value: MovementType.adjustment,
                    label: Text('Ajuster'),
                    icon: Icon(Icons.tune_rounded, size: 16)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _type == MovementType.adjustment
                    ? 'Nouvelle quantité totale'
                    : 'Quantité',
              ),
            ),
            const SizedBox(height: 12),
            if (_type == MovementType.entry && _suppliers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                  value: _selectedSupplierId,
                  decoration: const InputDecoration(
                      labelText: 'Fournisseur (optionnel)'),
                  items: _suppliers
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSupplierId = v),
                ),
              ),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                  labelText: 'Motif / note (optionnel)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('ENREGISTRER LE MOUVEMENT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
