import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import '../models/sale.dart';
import '../models/customer.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _amountController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);
  final DatabaseService _db = DatabaseService();
  bool _isProcessing = false;
  List<Customer> _customers = [];
  int? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _db.getAllCustomers().then((c) => setState(() => _customers = c));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final amountPaid = double.tryParse(_amountController.text) ?? 0;
    final change = amountPaid - cart.total;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total à payer', style: TextStyle(fontSize: 16)),
                    Text(
                      _currencyFormat.format(cart.total),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_customers.isNotEmpty) ...[
              const Text('Client (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                value: _selectedCustomerId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Aucun client sélectionné',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Aucun client'),
                  ),
                  ..._customers.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text('${c.name} (${c.loyaltyPoints} pts)'),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedCustomerId = v),
              ),
              const SizedBox(height: 20),
            ],
            const Text('Mode de paiement', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(value: PaymentMethod.cash, label: Text('Cash'), icon: Icon(Icons.money)),
                ButtonSegment(value: PaymentMethod.card, label: Text('Carte'), icon: Icon(Icons.credit_card)),
                ButtonSegment(value: PaymentMethod.mobileMoney, label: Text('Mobile'), icon: Icon(Icons.phone_android)),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (s) => setState(() => _selectedMethod = s.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant reçu (HTG)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (amountPaid > 0)
              Text(
                change >= 0
                    ? 'Monnaie à rendre : ${_currencyFormat.format(change)}'
                    : 'Montant insuffisant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: change >= 0 ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (amountPaid >= cart.total && !_isProcessing)
                    ? () => _completeSale(cart)
                    : null,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONFIRMER LA VENTE', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSale(CartProvider cart) async {
    setState(() => _isProcessing = true);

    final sale = Sale(
      date: DateTime.now(),
      items: cart.items,
      paymentMethod: _selectedMethod,
      amountPaid: double.parse(_amountController.text),
      customerId: _selectedCustomerId,
    );

    await _db.insertSale(sale);
    await _generateReceipt(sale);

    cart.clear();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pop(context);
  }

  Future<void> _generateReceipt(Sale sale) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text('SUPERMARCHÉ', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('Reçu de vente')),
            pw.Divider(),
            pw.Text('Date: ${sale.date}'),
            pw.SizedBox(height: 10),
            ...sale.items.map((item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${item.productName} x${item.quantity}'),
                    pw.Text(_currencyFormat.format(item.total)),
                  ],
                )),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_currencyFormat.format(sale.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Text('Payé: ${_currencyFormat.format(sale.amountPaid)}'),
            pw.Text('Monnaie: ${_currencyFormat.format(sale.change)}'),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('Merci de votre visite!')),
          ],
        ),
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'recu_${sale.date.millisecondsSinceEpoch}.pdf');
  }
}
