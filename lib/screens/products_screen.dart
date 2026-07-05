import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/category_provider.dart';
import '../providers/session_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  List<Product> _filtered = [];
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
        return query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.barcode.contains(query);
      }).toList();
    });
  }

  Future<void> _openEditSheet({Product? product}) async {
    final categoryNames = context.read<CategoryProvider>().names;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductEditSheet(
        db: _db,
        product: product,
        categoryNames: categoryNames,
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text(
            '${product.name} sera définitivement supprimé. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteProduct(product.id!);
      final employee = context.mounted
          ? context.read<SessionProvider>().currentEmployee
          : null;
      await _db.logActivity(
        employeeId: employee?.id,
        employeeName: employee?.name ?? 'Inconnu',
        action: 'Suppression produit',
        description: '${product.name} (${product.category})',
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('Aucun produit',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final product = _filtered[index];
                      final categoryProvider =
                          context.watch<CategoryProvider>();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _openEditSheet(product: product),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: categoryProvider
                                  .colorFor(product.category)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                                categoryProvider.iconFor(product.category),
                                color: categoryProvider
                                    .colorFor(product.category),
                                size: 18),
                          ),
                          title: Text(product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${product.category} · ${_currencyFormat.format(product.sellPrice)}'
                            '${product.sellPriceUSD > 0 ? ' · \$${product.sellPriceUSD.toStringAsFixed(2)}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.textSecondary, size: 20),
                            onPressed: () => _confirmDelete(product),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditSheet(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _ProductEditSheet extends StatefulWidget {
  final DatabaseService db;
  final Product? product;
  final List<String> categoryNames;

  const _ProductEditSheet({
    required this.db,
    required this.product,
    required this.categoryNames,
  });

  @override
  State<_ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends State<_ProductEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _purchasePriceUSDController;
  late final TextEditingController _sellPriceUSDController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;
  String? _selectedCategory;
  DateTime? _expiryDate;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _purchasePriceController =
        TextEditingController(text: p != null ? p.purchasePrice.toStringAsFixed(0) : '');
    _sellPriceController =
        TextEditingController(text: p != null ? p.sellPrice.toStringAsFixed(0) : '');
    _purchasePriceUSDController = TextEditingController(
        text: p != null && p.purchasePriceUSD > 0
            ? p.purchasePriceUSD.toStringAsFixed(2)
            : '');
    _sellPriceUSDController = TextEditingController(
        text: p != null && p.sellPriceUSD > 0
            ? p.sellPriceUSD.toStringAsFixed(2)
            : '');
    _stockController =
        TextEditingController(text: p != null ? '${p.stockQuantity}' : '0');
    _thresholdController =
        TextEditingController(text: p != null ? '${p.lowStockThreshold}' : '5');
    _selectedCategory = p?.category ??
        (widget.categoryNames.isNotEmpty ? widget.categoryNames.first : null);
    _expiryDate = p?.expiryDate;
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _fillUsdFromExchangeRate() async {
    final rateStr = await widget.db.getSetting('exchangeRate');
    final rate = double.tryParse(rateStr ?? '') ?? 130.0;
    if (rate <= 0) return;

    final purchaseHTG = double.tryParse(_purchasePriceController.text) ?? 0;
    final sellHTG = double.tryParse(_sellPriceController.text) ?? 0;

    setState(() {
      if (purchaseHTG > 0) {
        _purchasePriceUSDController.text = (purchaseHTG / rate).toStringAsFixed(2);
      }
      if (sellHTG > 0) {
        _sellPriceUSDController.text = (sellHTG / rate).toStringAsFixed(2);
      }
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom et la catégorie sont obligatoires'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final sellPrice = double.tryParse(_sellPriceController.text) ?? 0;
    final purchasePriceUSD =
        double.tryParse(_purchasePriceUSDController.text) ?? 0;
    final sellPriceUSD = double.tryParse(_sellPriceUSDController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final threshold = int.tryParse(_thresholdController.text) ?? 5;

    // Génère un code-barres local si aucun n'est fourni.
    final barcode = _barcodeController.text.trim().isEmpty
        ? 'LOCAL${DateTime.now().millisecondsSinceEpoch}'
        : _barcodeController.text.trim();

    setState(() => _saving = true);

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      barcode: barcode,
      category: _selectedCategory!,
      purchasePrice: purchasePrice,
      sellPrice: sellPrice,
      purchasePriceUSD: purchasePriceUSD,
      sellPriceUSD: sellPriceUSD,
      stockQuantity: stock,
      lowStockThreshold: threshold,
      expiryDate: _expiryDate,
    );

    try {
      if (_isEditing) {
        await widget.db.updateProduct(product);
        final priceChanged = widget.product!.sellPrice != sellPrice ||
            widget.product!.purchasePrice != purchasePrice;
        if (priceChanged && mounted) {
          final employee = context.read<SessionProvider>().currentEmployee;
          await widget.db.logActivity(
            employeeId: employee?.id,
            employeeName: employee?.name ?? 'Inconnu',
            action: 'Modification prix',
            description:
                '${product.name} : ${widget.product!.sellPrice.toStringAsFixed(0)} → ${sellPrice.toStringAsFixed(0)} HTG',
          );
        }
      } else {
        await widget.db.insertProduct(product);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce code-barres est déjà utilisé'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
              Text(_isEditing ? 'Modifier le produit' : 'Nouveau produit',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: widget.categoryNames
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                    labelText: 'Code-barres (optionnel)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                          labelText: 'Prix d\'achat (HTG)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _sellPriceController,
                      decoration: const InputDecoration(
                          labelText: 'Prix de vente (HTG)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _purchasePriceUSDController,
                      decoration: const InputDecoration(
                          labelText: 'Prix d\'achat (USD, optionnel)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _sellPriceUSDController,
                      decoration: const InputDecoration(
                          labelText: 'Prix de vente (USD, optionnel)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _fillUsdFromExchangeRate,
                  icon: const Icon(Icons.currency_exchange_rounded, size: 15),
                  label: const Text('Calculer via le taux de change',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      decoration:
                          const InputDecoration(labelText: 'Stock actuel'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _thresholdController,
                      decoration:
                          const InputDecoration(labelText: 'Seuil stock bas'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickExpiryDate,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Date de péremption (optionnel)'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate != null
                            ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                            : 'Aucune',
                        style: TextStyle(
                          color: _expiryDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (_expiryDate != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _expiryDate = null),
                        )
                      else
                        const Icon(Icons.calendar_today_rounded, size: 18),
                    ],
                  ),
                ),
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
                      : Text(_isEditing ? 'ENREGISTRER' : 'AJOUTER LE PRODUIT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
