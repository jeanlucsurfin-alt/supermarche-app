import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../utils/currency.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  final DatabaseService _db = DatabaseService();

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _printer.getBondedDevices();
    } catch (_) {
      return [];
    }
  }

  Future<bool> get isConnected async {
    final connected = await _printer.isConnected;
    return connected ?? false;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _printer.connect(device);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _printer.disconnect();
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

    final devices = await getPairedDevices();
    final match = devices.where((d) => d.address == address);
    if (match.isEmpty) return false;

    return await connect(match.first);
  }

  Future<bool> hasSavedPrinter() async {
    final address = await _db.getSetting('printerAddress');
    return address != null && address.isNotEmpty;
  }

  Future<void> savePrinter(BluetoothDevice device) async {
    await _db.setSetting('printerAddress', device.address ?? '');
    await _db.setSetting('printerName', device.name ?? 'Imprimante');
  }

  Future<String?> getSavedPrinterName() async {
    return _db.getSetting('printerName');
  }

  /// Imprime un reçu de vente au format ticket de caisse (texte brut,
  /// compatible avec la plupart des imprimantes thermiques 58/80mm).
  Future<bool> printReceipt(Sale sale) async {
    final connected = await ensureConnectedToSavedPrinter();
    if (!connected) return false;

    try {
      // Tailles : 0 = normal, 1 = moyen, 2 = grand (selon le pilote).
      _printer.printCustom('FAFOUTT STORE', 2, 1);
      _printer.printCustom('Point de Vente', 0, 1);
      _printer.printNewLine();
      _printer.printLeftRight('Date', _formatDate(sale.date), 0);
      _printer.printLeftRight('Devise', sale.currency, 0);
      _printer.printLeftRight(
          'Paiement', _paymentLabel(sale.paymentMethod), 0);
      _printer.printCustom('--------------------------------', 0, 1);

      for (final item in sale.items) {
        _printer.printLeftRight(
          '${item.productName} x${item.quantity}',
          formatPricePlain(item.total, sale.currency),
          0,
        );
      }

      _printer.printCustom('--------------------------------', 0, 1);
      if (sale.discountAmount > 0) {
        _printer.printLeftRight(
            'Sous-total', formatPricePlain(sale.subtotal, sale.currency), 0);
        _printer.printLeftRight(
            'Remise', '-${formatPricePlain(sale.discountAmount, sale.currency)}', 0);
      }
      _printer.printLeftRight(
          'TOTAL', formatPricePlain(sale.total, sale.currency), 1);
      _printer.printLeftRight(
          'Payé', formatPricePlain(sale.amountPaid, sale.currency), 0);
      _printer.printLeftRight(
          'Monnaie', formatPricePlain(sale.change, sale.currency), 0);
      _printer.printNewLine();
      _printer.printCustom('Merci pour votre confiance !', 1, 1);
      _printer.printNewLine();
      _printer.printNewLine();
      _printer.paperCut();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
}
