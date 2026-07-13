import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/cart_provider.dart';
import '../services/bluetooth_printer_service.dart';
import '../utils/receipt_pdf.dart';
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
  bool _manualDiscountEnabled = false;
  DiscountType _manualDiscountType = DiscountType.percentage;
  final TextEditingController _manualDiscountValueController =
      TextEditingController();

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

  double _promoDiscountAmount(double subtotal) {
    if (_appliedPromotion == null) return 0;
    return subtotal - _appliedPromotion!.applyTo(subtotal);
  }

  double _manualDiscountAmount(double remainingAfterPromo) {
    if (!_manualDiscountEnabled) return 0;
    final value = double.tryParse(_manualDiscountValueController.text) ?? 0;
    if (value <= 0) return 0;
    final amount = _manualDiscountType == DiscountType.percentage
        ? remainingAfterPromo * value / 100
        : value;
    return amount > remainingAfterPromo ? remainingAfterPromo : amount;
  }

  /// Remise totale (code promo + remise manuelle éventuelle), plafonnée
  /// pour ne jamais dépasser le sous-total.
  double _discountAmount(double subtotal) {
    final promo = _promoDiscountAmount(subtotal);
    final manual = _manualDiscountAmount(subtotal - promo);
    return promo + manual;
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Remise manuelle (sans code)',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Switch(
                        value: _manualDiscountEnabled,
                        activeColor: AppColors.navy,
                        onChanged: (v) =>
                            setState(() => _manualDiscountEnabled = v),
                      ),
                    ],
                  ),
                  if (_manualDiscountEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<DiscountType>(
                            segments: const [
                              ButtonSegment(
                                  value: DiscountType.percentage,
                                  label: Text('%')),
                              ButtonSegment(
                                  value: DiscountType.fixedAmount,
                                  label: Text('HTG')),
                            ],
                            selected: {_manualDiscountType},
                            onSelectionChanged: (s) => setState(
                                () => _manualDiscountType = s.first),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _manualDiscountValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: _manualDiscountType ==
                                      DiscountType.percentage
                                  ? 'Réduction (%)'
                                  : 'Réduction (HTG)',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
              style: SegmentedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              segments: const [
                ButtonSegment(value: PaymentMethod.cash, label: Text('Cash')),
                ButtonSegment(value: PaymentMethod.card, label: Text('Carte')),
                ButtonSegment(value: PaymentMethod.mobileMoney, label: Text('Mobile')),
                ButtonSegment(value: PaymentMethod.credit, label: Text('Crédit')),
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

    if (await BluetoothPrinterService().hasSavedPrinter()) {
      final printed = await BluetoothPrinterService().printReceipt(sale);
      if (mounted && !printed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Impossible d\'imprimer sur l\'imprimante Bluetooth (reçu PDF disponible)'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }

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
    await shareReceiptPdf(sale, db: _db);
  }
}
