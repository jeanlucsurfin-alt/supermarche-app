import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _sales = [];
  bool _loading = true;
  String _period = 'today';

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
    final now = DateTime.now();
    late DateTime start;
    switch (_period) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'all':
      default:
        start = DateTime(2020);
        break;
    }
    final sales = await _db.getSalesInRange(start, now);
    setState(() {
      _sales = sales;
      _loading = false;
    });
  }

  double get _totalRevenue =>
      _sales.fold(0.0, (sum, s) => sum + (s['total'] as num).toDouble());

  Future<void> _openDetail(Map<String, dynamic> sale) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaleDetailSheet(sale: sale, db: _db),
    );
  }

  Widget _periodChip(String value, String label) {
    final selected = _period == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _period = value);
          _load();
        },
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(
            color: selected ? AppColors.navy : const Color(0xFFE6DFD5),
          ),
        ),
      ),
    );
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
        return Icons.credit_card_outlined;
      case 'mobileMoney':
        return Icons.phone_android_outlined;
      case 'credit':
        return Icons.schedule_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Carte';
      case 'mobileMoney':
        return 'Mobile Money';
      case 'credit':
        return 'Crédit';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des ventes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _periodChip('today', 'Aujourd\'hui'),
                  _periodChip('week', '7 derniers jours'),
                  _periodChip('month', 'Ce mois'),
                  _periodChip('all', 'Tout'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text(
                  '${_sales.length} vente(s)',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  _currencyFormat.format(_totalRevenue),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? Center(
                        child: Text('Aucune vente sur cette période',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _sales.length,
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
                            final date = DateTime.parse(sale['date']);
                            final total = (sale['total'] as num).toDouble();
                            final method = sale['paymentMethod'] as String;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _openDetail(sale),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: method == 'credit'
                                        ? AppColors.clay
                                        : AppColors.navy,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(_paymentIcon(method),
                                      color: Colors.white, size: 18),
                                ),
                                title: Text(_dateFormat.format(date),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                subtitle: Text(
                                    '${_paymentLabel(method)} · ${sale['currency'] ?? 'HTG'}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _currencyFormat.format(total),
                                      style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                        size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SaleDetailSheet extends StatefulWidget {
  final Map<String, dynamic> sale;
  final DatabaseService db;
  const _SaleDetailSheet({required this.sale, required this.db});

  @override
  State<_SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<_SaleDetailSheet> {
  List<Map<String, dynamic>> _items = [];
  Customer? _customer;
  bool _loading = true;

  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

  int get _saleId => widget.sale['id'] as int;
  String get _currency => (widget.sale['currency'] as String?) ?? 'HTG';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.db.getSaleItemsForSale(_saleId);
    Customer? customer;
    final customerId = widget.sale['customerId'];
    if (customerId != null) {
      customer = await widget.db.getCustomerById(customerId as int);
    }
    setState(() {
      _items = items;
      _customer = customer;
      _loading = false;
    });
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Carte';
      case 'mobileMoney':
        return 'Mobile Money';
      case 'credit':
        return 'Crédit';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.sale['date']);
    final total = (widget.sale['total'] as num).toDouble();
    final amountPaid = (widget.sale['amountPaid'] as num).toDouble();
    final discount = (widget.sale['discountAmount'] as num?)?.toDouble() ?? 0;
    final subtotal = total + discount;
    final promoCode = widget.sale['promoCode'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                      color: const Color(0xFFDDD3C4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vente #$_saleId',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(_dateFormat.format(date),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.payments_outlined, size: 16),
                          label: Text(_paymentLabel(
                              widget.sale['paymentMethod'] as String)),
                        ),
                        if (_customer != null)
                          Chip(
                            avatar: const Icon(Icons.person_outline, size: 16),
                            label: Text(_customer!.name),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        ..._items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item['productName'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                        Text(
                                          '${item['quantity']} x ${_currencyFormat.format((item['unitPrice'] as num).toDouble())}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(
                                        (item['quantity'] as int) *
                                            (item['unitPrice'] as num)
                                                .toDouble()),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 20),
                        if (discount > 0) ...[
                          _totalRow('Sous-total', _currencyFormat.format(subtotal)),
                          _totalRow(
                              promoCode != null
                                  ? 'Remise ($promoCode)'
                                  : 'Remise',
                              '-${_currencyFormat.format(discount)}',
                              color: AppColors.success),
                        ],
                        _totalRow('TOTAL', _currencyFormat.format(total),
                            bold: true),
                        _totalRow('Payé', _currencyFormat.format(amountPaid)),
                        if (amountPaid > total)
                          _totalRow('Monnaie rendue',
                              _currencyFormat.format(amountPaid - total)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: bold ? 15 : 13,
                  color: color ?? AppColors.textPrimary)),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 16 : 13,
                  color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
