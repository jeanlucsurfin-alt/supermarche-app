import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_payment.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _debtors = [];
  double _totalOutstanding = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final debtors = await _db.getCustomersWithOutstandingBalance();
    final total = await _db.getTotalOutstandingCredit();
    setState(() {
      _debtors = debtors;
      _totalOutstanding = total;
      _loading = false;
    });
  }

  Future<void> _openDetail(Map<String, dynamic> debtor) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreditDetailSheet(
        customerId: debtor['id'],
        customerName: debtor['name'],
        db: _db,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créances')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.schedule_rounded,
                              color: AppColors.danger, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total des créances en cours',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                              Text(
                                formatHTG(_totalOutstanding),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_debtors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 40, color: AppColors.success),
                            const SizedBox(height: 8),
                            Text('Aucune créance en cours',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._debtors.map((debtor) {
                      final balance = (debtor['balance'] as num).toDouble();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _openDetail(debtor),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.danger.withOpacity(0.1),
                            child: Text(
                              (debtor['name'] as String).isNotEmpty
                                  ? (debtor['name'] as String)[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(debtor['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(debtor['phone'],
                              style: const TextStyle(fontSize: 12)),
                          trailing: Text(
                            formatHTG(balance),
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _CreditDetailSheet extends StatefulWidget {
  final int customerId;
  final String customerName;
  final DatabaseService db;

  const _CreditDetailSheet({
    required this.customerId,
    required this.customerName,
    required this.db,
  });

  @override
  State<_CreditDetailSheet> createState() => _CreditDetailSheetState();
}

class _CreditDetailSheetState extends State<_CreditDetailSheet> {
  double _balance = 0;
  List<Map<String, dynamic>> _creditSales = [];
  List<CreditPayment> _payments = [];
  bool _loading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final balance =
        await widget.db.getOutstandingBalanceForCustomer(widget.customerId);
    final sales = await widget.db.getCreditSalesForCustomer(widget.customerId);
    final payments =
        await widget.db.getCreditPaymentsForCustomer(widget.customerId);
    setState(() {
      _balance = balance;
      _creditSales = sales;
      _payments = payments;
      _loading = false;
    });
  }

  Future<void> _openRepaymentDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer un remboursement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Solde actuel : ${formatHTG(_balance)}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Montant reçu (HTG)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Montant invalide'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              await widget.db.insertCreditPayment(CreditPayment(
                customerId: widget.customerId,
                amount: amount,
                date: DateTime.now(),
                note: noteController.text.isEmpty ? null : noteController.text,
              ));
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customerName,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Solde dû',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                formatHTG(_balance),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _openRepaymentDialog,
                            icon: const Icon(Icons.payments_rounded, size: 18),
                            label: const Text('ENREGISTRER UN REMBOURSEMENT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Text('Ventes à crédit',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_creditSales.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text('Aucune',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          )
                        else
                          ..._creditSales.map((sale) {
                            final date = DateTime.parse(sale['date']);
                            final total = (sale['total'] as num).toDouble();
                            final paid = (sale['amountPaid'] as num).toDouble();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded,
                                      size: 16, color: AppColors.navy),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_dateFormat.format(date),
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  Text(
                                    '${formatHTG(paid)} / ${formatHTG(total)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 16),
                        Text('Remboursements',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_payments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text('Aucun remboursement enregistré',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          )
                        else
                          ..._payments.map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded,
                                        size: 16, color: AppColors.success),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _dateFormat.format(p.date) +
                                            (p.note != null
                                                ? ' · ${p.note}'
                                                : ''),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      formatHTG(p.amount),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success),
                                    ),
                                  ],
                                ),
                              )),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
