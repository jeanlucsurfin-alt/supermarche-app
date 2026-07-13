import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import 'currency.dart';

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

pw.Widget _receiptInfoRow(String label, String value, PdfColor greyText) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: greyText)),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}

/// Génère le reçu PDF d'une vente (nouvelle vente ou réimpression depuis
/// l'historique) et ouvre la fenêtre de partage/impression du téléphone.
Future<void> shareReceiptPdf(Sale sale, {DatabaseService? db}) async {
  final database = db ?? DatabaseService();
  final navy = PdfColor.fromInt(0xFF14264A);
  final gold = PdfColor.fromInt(0xFFD4AF37);
  final greyText = PdfColor.fromInt(0xFF6B7280);
  final lightGrey = PdfColor.fromInt(0xFFEBEDF2);

  final settings = await database.getAllSettings();
  final storeName = (settings['storeName'] ?? '').trim().isEmpty
      ? 'FAFOUTT STORE'
      : settings['storeName']!.toUpperCase();
  final storeAddress = settings['storeAddress'] ?? '';
  final storePhone = settings['storePhone'] ?? '';

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
                  storeName,
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
                if (storeAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    storeAddress,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 8, color: greyText),
                  ),
                ],
                if (storePhone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Tél : $storePhone',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 8, color: greyText),
                  ),
                ],
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
                            '${formatPricePlain(item.unitPrice, sale.currency)} / unité',
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
  await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'recu_${sale.date.millisecondsSinceEpoch}.pdf');
}
