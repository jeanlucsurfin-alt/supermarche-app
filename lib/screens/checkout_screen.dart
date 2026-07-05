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
import '../models/promotion.dart';
import '../utils/currency.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  bool _isProcessing = false;
  bool _checkingPromo = false;
  List<Customer> _customers = [];
  int? _selectedCustomerId;
  Promotion? _appliedPromotion;
  String? _promoError;

  @override
  void initState() {
    super.initState();
    _db.getAllCustomers().then((c) => setState(() => _customers = c));
  }

  Future<void> _applyPromoCode(double subtotal) async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _checkingPromo = true;
      _promoError = null;
    });
    final promo = await _db.findPromoByCode(code);
    setState(() {
      _checkingPromo = false;
      if (promo == null) {
        _appliedPromotion = null;
        _promoError = 'Code promo invalide ou expiré';
      } else {
        _appliedPromotion = promo;
        _promoError = null;
      }
    });
  }

  void _removePromo() {
    setState(() {
      _appliedPromotion = null;
      _promoCodeController.clear();
      _promoError = null;
    });
  }

  double _discountAmount(double subtotal) {
    if (_appliedPromotion == null) return 0;
    return subtotal - _appliedPromotion!.applyTo(subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = cart.currency;
    final isCredit = _selectedMethod == PaymentMethod.credit;
    final subtotal = cart.total;
    final discount = _discountAmount(subtotal);
    final payableTotal = (subtotal - discount).clamp(0, double.infinity).toDouble();
    final amountPaid = double.tryParse(_amountController.text) ?? 0;
    final change = amountPaid - payableTotal;
    final creditBalance = payableTotal - amountPaid;

    final canConfirm = !_isProcessing &&
        (isCredit
            ? _selectedCustomerId != null && amountPaid <= payableTotal
            : amountPaid >= payableTotal);

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
                    if (discount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        formatPrice(subtotal, currency),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'Remise : -${formatPrice(discount, currency)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                    Text(
                      formatPrice(payableTotal, currency),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    enabled: _appliedPromotion == null,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Code promo (optionnel)',
                      border: const OutlineInputBorder(),
                      errorText: _promoError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: _appliedPromotion != null
                      ? OutlinedButton(
                          onPressed: _removePromo,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger),
                          child: const Text('Retirer'),
                        )
                      : ElevatedButton(
                          onPressed: _checkingPromo
                              ? null
                              : () => _applyPromoCode(subtotal),
                          child: _checkingPromo
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Appliquer'),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(isCredit ? 'Client (obligatoire pour le crédit)' : 'Client (optionnel)',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedCustomerId,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Aucun client sélectionné',
                errorText: isCredit && _selectedCustomerId == null
                    ? 'Un client est requis pour une vente à crédit'
                    : null,
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
            const Text('Mode de paiement', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(value: PaymentMethod.cash, label: Text('Cash'), icon: Icon(Icons.money)),
                ButtonSegment(value: PaymentMethod.card, label: Text('Carte'), icon: Icon(Icons.credit_card)),
                ButtonSegment(value: PaymentMethod.mobileMoney, label: Text('Mobile'), icon: Icon(Icons.phone_android)),
                ButtonSegment(value: PaymentMethod.credit, label: Text('Crédit'), icon: Icon(Icons.schedule_rounded)),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (s) => setState(() => _selectedMethod = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isCredit
                    ? 'Acompte versé ($currency, optionnel)'
                    : 'Montant reçu ($currency)',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (isCredit)
              Text(
                amountPaid > payableTotal
                    ? 'L\'acompte ne peut pas dépasser le total'
                    : 'Solde restant à crédit : ${formatPrice(creditBalance, currency)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountPaid > payableTotal
                      ? Colors.red
                      : AppColors.danger,
                ),
              )
            else if (amountPaid > 0)
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
                onPressed: canConfirm ? () => _completeSale(cart) : null,
                style: isCredit
                    ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger)
                    : null,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isCredit ? 'ENREGISTRER LA VENTE À CRÉDIT' : 'CONFIRMER LA VENTE',
                        style: const TextStyle(fontSize: 16),
                      ),
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
      amountPaid: double.tryParse(_amountController.text) ?? 0,
      customerId: _selectedCustomerId,
      currency: cart.currency,
      discountAmount: _discountAmount(cart.total),
      promoCode: _appliedPromotion?.promoCode,
    );

    await _db.insertSale(sale);
    await _generateReceipt(sale);

    cart.clear();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pop(context);
  }

  String _paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Carte bancaire';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Crédit';
    }
  }

  Future<void> _generateReceipt(Sale sale) async {
    final navy = PdfColor.fromInt(0xFF14264A);
    final gold = PdfColor.fromInt(0xFFD4AF37);
    final greyText = PdfColor.fromInt(0xFF6B7280);
    final lightGrey = PdfColor.fromInt(0xFFEBEDF2);

    final receiptNumber =
        'FS-${sale.date.millisecondsSinceEpoch.toString().substring(6)}';
    final dateLabel = DateFormat('dd/MM/yyyy à HH:mm').format(sale.date);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // En-tête
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Column(
                children: [
                  pw.Text(
                    'FAFOUTT STORE',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: navy,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Point de Vente',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9, color: greyText),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(height: 2, color: gold),
            pw.SizedBox(height: 10),

            // Infos de la transaction
            _receiptInfoRow('Reçu N°', receiptNumber, greyText),
            _receiptInfoRow('Date', dateLabel, greyText),
            _receiptInfoRow('Devise', sale.currency, greyText),
            _receiptInfoRow(
                'Paiement', _paymentMethodLabel(sale.paymentMethod), greyText),

            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: lightGrey, width: 1),
                  bottom: pw.BorderSide(color: lightGrey, width: 1),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Article',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: navy)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('Qté',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: navy)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: navy)),
                  ),
                ],
              ),
            ),
            ...sale.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.productName,
                                style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(
                              formatPricePlain(item.unitPrice, sale.currency) +
                                  ' / unité',
                              style:
                                  pw.TextStyle(fontSize: 7.5, color: greyText),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text('${item.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          formatPricePlain(item.total, sale.currency),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )),
            pw.Container(height: 1, color: lightGrey),
            pw.SizedBox(height: 8),

            // Total
            if (sale.discountAmount > 0) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sous-total',
                      style: pw.TextStyle(fontSize: 10, color: greyText)),
                  pw.Text(formatPricePlain(sale.subtotal, sale.currency),
                      style: pw.TextStyle(fontSize: 10, color: greyText)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      sale.promoCode != null
                          ? 'Remise (${sale.promoCode})'
                          : 'Remise',
                      style: pw.TextStyle(fontSize: 10, color: greyText)),
                  pw.Text('-${formatPricePlain(sale.discountAmount, sale.currency)}',
                      style: pw.TextStyle(fontSize: 10, color: greyText)),
                ],
              ),
              pw.SizedBox(height: 4),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold, color: navy)),
                pw.Text(
                  formatPricePlain(sale.total, sale.currency),
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold, color: navy),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            _receiptInfoRow(
                'Montant payé',
                formatPricePlain(sale.amountPaid, sale.currency),
                greyText),
            _receiptInfoRow(
                'Monnaie rendue',
                formatPricePlain(sale.change, sale.currency),
                greyText),

            pw.SizedBox(height: 18),
            pw.Container(height: 2, color: gold),
            pw.SizedBox(height: 10),
            pw.Text(
              'Merci pour votre confiance !',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: navy),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'À bientôt chez Fafoutt Store',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8, color: greyText),
            ),
          ],
        ),
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'recu_${sale.date.millisecondsSinceEpoch}.pdf');
  }

  pw.Widget _receiptInfoRow(String label, String value, PdfColor greyText) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: greyText)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
