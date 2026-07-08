import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../models/supplier.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

String _statusLabel(PurchaseOrderStatus status, String lang) {
  switch (status) {
    case PurchaseOrderStatus.pending:
      return tr(lang, 'orders_status_pending');
    case PurchaseOrderStatus.partiallyReceived:
      return tr(lang, 'orders_status_partial');
    case PurchaseOrderStatus.received:
      return tr(lang, 'orders_status_received');
  }
}

class SupplierOrdersScreen extends StatefulWidget {
  final Supplier supplier;
  const SupplierOrdersScreen({super.key, required this.supplier});

  @override
  State<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends State<SupplierOrdersScreen> {
  final DatabaseService _db = DatabaseService();
  List<PurchaseOrder> _orders = [];
  bool _loading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _db.getPurchaseOrdersForSupplier(widget.supplier.id!);
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  Color _statusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.pending:
        return AppColors.gold;
      case PurchaseOrderStatus.partiallyReceived:
        return AppColors.blue;
      case PurchaseOrderStatus.received:
        return AppColors.success;
    }
  }

  Future<void> _openNewOrder() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewOrderSheet(supplier: widget.supplier, db: _db),
    );
    if (created == true) _load();
  }

  Future<void> _openOrderDetail(PurchaseOrder order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order, db: _db),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
    return Scaffold(
      appBar: AppBar(title: Text(widget.supplier.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 40, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(tr(lang, 'orders_empty'),
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final color = _statusColor(order.status);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _openOrderDetail(order),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.local_shipping_rounded,
                              color: color, size: 18),
                        ),
                        title: Text('${tr(lang, 'orders_order_number')} #${order.id}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_dateFormat.format(order.date)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(order.status, lang),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        onPressed: _openNewOrder,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr(lang, 'orders_new_button')),
      ),
    );
  }
}

class _NewOrderSheet extends StatefulWidget {
  final Supplier supplier;
  final DatabaseService db;
  const _NewOrderSheet({required this.supplier, required this.db});

  @override
  State<_NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<_NewOrderSheet> {
  List<Product> _products = [];
  final Map<int, int> _quantities = {};
  bool _loading = true;
  bool _saving = false;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await widget.db.getAllProducts();
    setState(() {
      _products = products;
      _filtered = products;
      _loading = false;
    });
  }

  void _applyFilter(String query) {
    setState(() {
      _filtered = _products
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _save() async {
    final lang = context.read<LocaleProvider>().language;
    final selected = _quantities.entries.where((e) => e.value > 0).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'orders_add_product_qty')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final items = selected.map((e) {
      final product = _products.firstWhere((p) => p.id == e.key);
      return PurchaseOrderItem(
        productId: product.id!,
        productName: product.name,
        quantityOrdered: e.value,
        unitPrice: product.purchasePrice,
      );
    }).toList();

    await widget.db.createPurchaseOrder(
      PurchaseOrder(
        supplierId: widget.supplier.id!,
        supplierName: widget.supplier.name,
        date: DateTime.now(),
      ),
      items,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6EC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(tr(lang, 'orders_new_title'),
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                          hintText: tr(lang, 'orders_search_product')),
                      onChanged: _applyFilter,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final product = _filtered[index];
                        final qty = _quantities[product.id] ?? 0;
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
                                child: Text(product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20),
                                onPressed: qty > 0
                                    ? () => setState(
                                        () => _quantities[product.id!] = qty - 1)
                                    : null,
                              ),
                              SizedBox(
                                  width: 28,
                                  child: Text('$qty',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700))),
                              IconButton(
                                icon:
                                    const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => setState(
                                    () => _quantities[product.id!] = qty + 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
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
                            : Text(tr(lang, 'orders_create_button')),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final PurchaseOrder order;
  final DatabaseService db;
  const _OrderDetailSheet({required this.order, required this.db});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  List<PurchaseOrderItem> _items = [];
  final Map<int, int> _toReceive = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.db.getPurchaseOrderItems(widget.order.id!);
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _receive() async {
    final lang = context.read<LocaleProvider>().language;
    final quantities = <int, int>{
      for (final item in _items)
        if ((_toReceive[item.id] ?? 0) > 0) item.id!: _toReceive[item.id]!
    };
    if (quantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'orders_receive_at_least_one')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await widget.db.receivePurchaseOrderItems(widget.order.id!, quantities);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6EC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('${tr(lang, 'orders_order_number')} #${widget.order.id}',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: _items.map((item) {
                        final toReceive = _toReceive[item.id] ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(
                                '${tr(lang, 'orders_ordered')} ${item.quantityOrdered} · ${tr(lang, 'orders_received')} ${item.quantityReceived} · ${tr(lang, 'orders_remaining')} ${item.remaining}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 11),
                              ),
                              if (item.remaining > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text('${tr(lang, 'orders_receive_now')} ',
                                        style: const TextStyle(fontSize: 12)),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18),
                                      onPressed: toReceive > 0
                                          ? () => setState(() =>
                                              _toReceive[item.id!] =
                                                  toReceive - 1)
                                          : null,
                                    ),
                                    Text('$toReceive',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 18),
                                      onPressed: toReceive < item.remaining
                                          ? () => setState(() =>
                                              _toReceive[item.id!] =
                                                  toReceive + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _receive,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(tr(lang, 'orders_receive_button')),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
