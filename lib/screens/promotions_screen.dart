import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/promotion.dart';
import '../providers/category_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Promotion> _promotions = [];
  bool _loading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final promotions = await _db.getAllPromotions();
    setState(() {
      _promotions = promotions;
      _loading = false;
    });
  }

  String _valueLabel(Promotion promo) {
    return promo.discountType == DiscountType.percentage
        ? '-${promo.discountValue.toStringAsFixed(0)}%'
        : '-${promo.discountValue.toStringAsFixed(0)} HTG';
  }

  String _scopeLabel(Promotion promo, String lang) {
    switch (promo.scope) {
      case PromotionScope.product:
        return promo.targetProductName ?? tr(lang, 'promotions_product');
      case PromotionScope.category:
        return promo.targetCategory ?? tr(lang, 'promotions_category');
      case PromotionScope.cart:
        return '${tr(lang, 'promo_code_prefix')} : ${promo.promoCode}';
    }
  }

  Future<void> _openAddDialog() async {
    final lang = context.read<LocaleProvider>().language;
    final products = await _db.getAllProducts();
    if (!mounted) return;
    final categoryNames = context.read<CategoryProvider>().names;

    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final codeController = TextEditingController();
    DiscountType discountType = DiscountType.percentage;
    PromotionScope scope = PromotionScope.product;
    Product? selectedProduct = products.isNotEmpty ? products.first : null;
    String? selectedCategory =
        categoryNames.isNotEmpty ? categoryNames.first : null;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    String scopeLabel(PromotionScope s) {
      switch (s) {
        case PromotionScope.product:
          return tr(lang, 'promo_scope_product');
        case PromotionScope.category:
          return tr(lang, 'promo_scope_category');
        case PromotionScope.cart:
          return tr(lang, 'promo_scope_cart');
      }
    }

    String discountTypeLabel(DiscountType t) {
      return t == DiscountType.percentage
          ? tr(lang, 'promo_discount_percentage')
          : tr(lang, 'promo_discount_fixed');
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr(lang, 'promotions_new')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: tr(lang, 'promotions_name')),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PromotionScope>(
                  value: scope,
                  decoration: InputDecoration(labelText: tr(lang, 'promotions_applies_to')),
                  items: PromotionScope.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(scopeLabel(s))))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => scope = v ?? scope),
                ),
                const SizedBox(height: 12),
                if (scope == PromotionScope.product)
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: InputDecoration(labelText: tr(lang, 'promotions_product')),
                    items: products
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedProduct = v),
                  )
                else if (scope == PromotionScope.category)
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(labelText: tr(lang, 'promotions_category')),
                    items: categoryNames
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCategory = v),
                  )
                else
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                        labelText: tr(lang, 'promotions_code_hint')),
                    textCapitalization: TextCapitalization.characters,
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DiscountType>(
                  value: discountType,
                  decoration: InputDecoration(labelText: tr(lang, 'promotions_discount_type')),
                  items: DiscountType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(discountTypeLabel(t))))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => discountType = v ?? discountType),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: discountType == DiscountType.percentage
                        ? tr(lang, 'promotions_discount_percent')
                        : tr(lang, 'promotions_discount_amount'),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: tr(lang, 'promotions_start')),
                          child: Text(_dateFormat.format(startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: tr(lang, 'promotions_end')),
                          child: Text(_dateFormat.format(endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(lang, 'common_cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = double.tryParse(valueController.text);
                if (nameController.text.trim().isEmpty || value == null || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr(lang, 'promotions_name_value_required')),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (scope == PromotionScope.cart &&
                    codeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr(lang, 'promotions_code_required')),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (endDate.isBefore(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr(lang, 'promotions_end_after_start')),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }

                await _db.insertPromotion(Promotion(
                  name: nameController.text.trim(),
                  discountType: discountType,
                  discountValue: value,
                  scope: scope,
                  targetProductId:
                      scope == PromotionScope.product ? selectedProduct?.id : null,
                  targetProductName:
                      scope == PromotionScope.product ? selectedProduct?.name : null,
                  targetCategory:
                      scope == PromotionScope.category ? selectedCategory : null,
                  promoCode: scope == PromotionScope.cart
                      ? codeController.text.trim().toUpperCase()
                      : null,
                  startDate: startDate,
                  endDate: endDate,
                ));
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(tr(lang, 'promotions_create')),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Promotion promo) async {
    final lang = context.read<LocaleProvider>().language;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(lang, 'promotions_delete_title')),
        content: Text('${promo.name} ${tr(lang, 'promotions_delete_suffix')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(lang, 'common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(lang, 'common_delete'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deletePromotion(promo.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'promotions_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
              ? Center(
                  child: Text(tr(lang, 'promotions_empty'),
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _promotions.length,
                  itemBuilder: (context, index) {
                    final promo = _promotions[index];
                    final active = promo.isActiveOn(now);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: active ? AppColors.success : AppColors.textSecondary,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.local_offer_rounded,
                              color: Colors.white,
                              size: 18),
                        ),
                        title: Text(promo.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${_scopeLabel(promo, lang)} · ${_dateFormat.format(promo.startDate)} - ${_dateFormat.format(promo.endDate)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_valueLabel(promo),
                                  style: const TextStyle(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.textSecondary, size: 18),
                              onPressed: () => _confirmDelete(promo),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        onPressed: _openAddDialog,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr(lang, 'common_add')),
      ),
    );
  }
}
