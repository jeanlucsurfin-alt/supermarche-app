import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../utils/currency.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _amountController = TextEditingController();
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
    final currency = cart.currency;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Total à payer', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EAD6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(currency,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    Text(
                      formatPrice(cart.total, currency),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Montant reçu ($currency)',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (amountPaid > 0)
              Text(
                change >= 0
                    ? 'Monnaie à rendre : ${formatPrice(change, currency)}'
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
      currency: cart.currency,
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
            pw.Center(child: pw.Text('FAFOUTT STORE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('Reçu de vente')),
            pw.Divider(),
            pw.Text('Date: ${sale.date}'),
            pw.Text('Devise: ${sale.currency}'),
            pw.SizedBox(height: 10),
            ...sale.items.map((item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${item.productName} x${item.quantity}'),
                    pw.Text(formatPricePlain(item.total, sale.currency)),
                  ],
                )),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(formatPricePlain(sale.total, sale.currency), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Text('Payé: ${formatPricePlain(sale.amountPaid, sale.currency)}'),
            pw.Text('Monnaie: ${formatPricePlain(sale.change, sale.currency)}'),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('Merci de votre visite!')),
          ],
        ),
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'recu_${sale.date.millisecondsSinceEpoch}.pdf');
  }
}
