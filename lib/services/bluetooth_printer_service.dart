import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../utils/currency.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final DatabaseService _db = DatabaseService();

  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (_) {
      return [];
    }
  }

  Future<bool> get isConnected async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {
      // Ignoré : l'imprimante était peut-être déjà déconnectée.
    }
  }

  /// Reconnecte automatiquement à l'imprimante enregistrée dans les
  /// paramètres, si elle n'est pas déjà connectée.
  Future<bool> ensureConnectedToSavedPrinter() async {
    if (await isConnected) return true;

    final address = await _db.getSetting('printerAddress');
    if (address == null || address.isEmpty) return false;

    return await connect(address);
  }

  Future<bool> hasSavedPrinter() async {
    final address = await _db.getSetting('printerAddress');
    return address != null && address.isNotEmpty;
  }

  Future<void> savePrinter(BluetoothInfo device) async {
    await _db.setSetting('printerAddress', device.macAdress);
    await _db.setSetting('printerName', device.name);
  }

  Future<String?> getSavedPrinterName() async {
    return _db.getSetting('printerName');
  }

  String _line(String left, String right, {int width = 32}) {
    final space = width - left.length - right.length;
    if (space <= 1) return '$left $right';
    return left + ' ' * space + right;
  }

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Crédit';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Imprime un reçu de vente au format ticket de caisse (texte brut,
  /// compatible avec la plupart des imprimantes thermiques 58/80mm).
  Future<bool> printReceipt(Sale sale) async {
    final connected = await ensureConnectedToSavedPrinter();
    if (!connected) return false;

    try {
      final lines = <String>[];
      lines.add('FAFOUTT STORE');
      lines.add('Point de Vente');
      lines.add('--------------------------------');
      lines.add(_line('Date', _formatDate(sale.date)));
      lines.add(_line('Devise', sale.currency));
      lines.add(_line('Paiement', _paymentLabel(sale.paymentMethod)));
      lines.add('--------------------------------');

      for (final item in sale.items) {
        lines.add(_line('${item.productName} x${item.quantity}',
            formatPricePlain(item.total, sale.currency)));
      }

      lines.add('--------------------------------');
      if (sale.discountAmount > 0) {
        lines.add(_line(
            'Sous-total', formatPricePlain(sale.subtotal, sale.currency)));
        lines.add(_line('Remise',
            '-${formatPricePlain(sale.discountAmount, sale.currency)}'));
      }
      lines.add(_line('TOTAL', formatPricePlain(sale.total, sale.currency)));
      lines.add(
          _line('Payé', formatPricePlain(sale.amountPaid, sale.currency)));
      lines.add(
          _line('Monnaie', formatPricePlain(sale.change, sale.currency)));
      lines.add('');
      lines.add('Merci pour votre confiance !');
      lines.add('');
      lines.add('');

      for (final line in lines) {
        await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 1, text: line),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
