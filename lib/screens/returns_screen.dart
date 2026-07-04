import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sale_return.dart';
import '../providers/session_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';
import '../widgets/logout_button.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _sales = [];
  bool _loading = true;
  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sales = await _db.getRecentSales();
    setState(() {
      _sales = sales;
      _loading = false;
    });
  }

  Future<void> _openSale(Map<String, dynamic> sale) async {
    final processed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReturnSheet(sale: sale, db: _db),
    );
    if (processed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FafouttHeader(subtitle: 'Retours et remboursements'),
        actions: const [LogoutButton(), SizedBox(width: 4)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sales.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text('Aucune vente enregistrée',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sales.length,
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        final date = DateTime.parse(sale['date']);
                        final total = (sale['total'] as num).toDouble();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _openSale(sale),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: AppColors.navy, size: 18),
                            ),
                            title: Text(_dateFormat.format(date),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(
                                '${sale['currency'] ?? 'HTG'} · ${sale['paymentMethod']}'),
                            trailing: Text(
                              _currencyFormat.format(total),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _ReturnSheet extends StatefulWidget {
  final Map<String, dynamic> sale;
  final DatabaseService db;
  const _ReturnSheet({required this.sale, required this.db});

  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  List<Map<String, dynamic>> _items = [];
  Map<int, int> _returnQuantities = {};
  Map<int, int> _alreadyReturned = {};
  bool _loading = true;
  bool _saving = false;
  final TextEditingController _reasonController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);

  int get _saleId => widget.sale['id'] as int;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.db.getSaleItemsForSale(_saleId);
    final returned = <int, int>{};
    for (final item in items) {
      final productId = item['productId'] as int;
      returned[productId] =
          await widget.db.getReturnedQuantity(_saleId, productId);
    }
    setState(() {
      _items = items;
      _alreadyReturned = returned;
      _returnQuantities = {for (final item in items) item['productId'] as int: 0};
      _loading = false;
    });
  }

  int _maxReturnable(Map<String, dynamic> item) {
    final sold = item['quantity'] as int;
    final already = _alreadyReturned[item['productId']] ?? 0;
    final max = sold - already;
    return max < 0 ? 0 : max;
  }

  double get _totalToRefund {
    double total = 0;
    for (final item in _items) {
      final productId = item['productId'] as int;
      final qty = _returnQuantities[productId] ?? 0;
      final unitPrice = (item['unitPrice'] as num).toDouble();
      total += qty * unitPrice;
    }
    return total;
  }

  Future<void> _confirmReturn() async {
    final employee = context.read<SessionProvider>().currentEmployee;
    if (employee == null) return;

    final itemsToReturn = <ReturnItem>[];
    for (final item in _items) {
      final productId = item['productId'] as int;
      final qty = _returnQuantities[productId] ?? 0;
      if (qty > 0) {
        itemsToReturn.add(ReturnItem(
          productId: productId,
          productName: item['productName'],
          quantity: qty,
          unitPrice: (item['unitPrice'] as num).toDouble(),
        ));
      }
    }

    if (itemsToReturn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un article à retourner'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le retour ?'),
        content: Text(
            'Remboursement de ${_currencyFormat.format(_totalToRefund)}. Le stock des articles sera automatiquement remis à jour.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer le retour'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    await widget.db.processReturn(SaleReturn(
      saleId: _saleId,
      date: DateTime.now(),
      employeeId: employee.id!,
      employeeName: employee.name,
      reason:
          _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      items: itemsToReturn,
    ));

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
                    child: Text('Sélectionner les articles à retourner',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        ..._items.map((item) {
                          final productId = item['productId'] as int;
                          final max = _maxReturnable(item);
                          final qty = _returnQuantities[productId] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['productName'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      Text(
                                        max > 0
                                            ? 'Vendu ${item['quantity']} · Retournable $max'
                                            : 'Déjà entièrement retourné',
                                        style: TextStyle(
                                            color: max > 0
                                                ? AppColors.textSecondary
                                                : AppColors.danger,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  onPressed: qty > 0
                                      ? () => setState(
                                          () => _returnQuantities[productId] =
                                              qty - 1)
                                      : null,
                                ),
                                SizedBox(
                                    width: 24,
                                    child: Text('$qty',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700))),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20),
                                  onPressed: qty < max
                                      ? () => setState(
                                          () => _returnQuantities[productId] =
                                              qty + 1)
                                      : null,
                                ),
                              ],
                            ),
                          );
                        }),
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                              labelText: 'Motif du retour (optionnel)'),
                        ),
                        const SizedBox(height: 20),
                      ],
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
                            const Text('Total à rembourser',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              _currencyFormat.format(_totalToRefund),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            onPressed: _saving ? null : _confirmReturn,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('CONFIRMER LE RETOUR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
