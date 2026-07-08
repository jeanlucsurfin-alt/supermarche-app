import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/product.dart';
import '../providers/category_provider.dart';
import '../providers/session_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
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

  Future<void> _printLabel(Product product) async {
    final pdf = pw.Document();
    // Format étiquette compact (environ 6cm x 4cm).
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(6 * PdfPageFormat.cm, 4 * PdfPageFormat.cm,
            marginAll: 6),
        build: (context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              product.name,
              textAlign: pw.TextAlign.center,
              maxLines: 2,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _currencyFormat.format(product.sellPrice),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: product.barcode,
              width: 140,
              height: 40,
              drawText: false,
            ),
            pw.SizedBox(height: 2),
            pw.Text(product.barcode, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'etiquette_${product.name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final lang = context.read<LocaleProvider>().language;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(lang, 'products_delete_title')),
        content: Text(
            '${product.name} ${tr(lang, 'products_delete_content_suffix')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(lang, 'common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text(tr(lang, 'common_delete'), style: const TextStyle(color: AppColors.danger)),
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
    final lang = context.watch<LocaleProvider>().language;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(lang, 'products_title')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr(lang, 'products_search_hint'),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(tr(lang, 'products_empty'),
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
                                  .colorFor(product.category),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                                categoryProvider.iconFor(product.category),
                                color: Colors.white,
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code_2_rounded,
                                    color: AppColors.textSecondary, size: 20),
                                tooltip: tr(lang, 'products_generate_label'),
                                onPressed: () => _printLabel(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.textSecondary, size: 20),
                                onPressed: () => _confirmDelete(product),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        onPressed: () => _openEditSheet(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr(lang, 'common_add')),
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
    final lang = context.read<LocaleProvider>().language;
    if (_nameController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'products_name_category_required')),
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
        final lang = context.read<LocaleProvider>().language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(lang, 'products_barcode_used')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
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
              Text(_isEditing ? tr(lang, 'products_edit') : tr(lang, 'products_new'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: tr(lang, 'products_name')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: tr(lang, 'products_category')),
                items: widget.categoryNames
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                    labelText: tr(lang, 'products_barcode')),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _purchasePriceController,
                      decoration: InputDecoration(
                          labelText: tr(lang, 'products_purchase_price')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _sellPriceController,
                      decoration: InputDecoration(
                          labelText: tr(lang, 'products_sell_price')),
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
                      decoration: InputDecoration(
                          labelText: tr(lang, 'products_purchase_price_usd')),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _sellPriceUSDController,
                      decoration: InputDecoration(
                          labelText: tr(lang, 'products_sell_price_usd')),
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
                  label: Text(tr(lang, 'products_calc_via_rate'),
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      decoration:
                          InputDecoration(labelText: tr(lang, 'products_current_stock')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _thresholdController,
                      decoration:
                          InputDecoration(labelText: tr(lang, 'products_low_stock_threshold')),
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
                      InputDecoration(labelText: tr(lang, 'products_expiry_date')),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate != null
                            ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                            : tr(lang, 'products_none'),
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
                      : Text(_isEditing
                          ? tr(lang, 'products_save_button')
                          : tr(lang, 'products_add_button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
