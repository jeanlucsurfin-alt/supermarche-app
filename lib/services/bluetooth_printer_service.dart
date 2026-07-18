import 'package:permission_handler/permission_handler.dart';
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

  /// Demande les permissions Bluetooth nécessaires (obligatoire sur
  /// Android 12+ : les déclarer dans le manifeste ne suffit pas, il faut
  /// explicitement demander l'autorisation à l'utilisateur au moment venu).
  /// Retourne true si les permissions sont accordées.
  Future<bool> requestPermissions() async {
    // Note : on ne demande PAS Permission.bluetooth (legacy). Dans le
    // manifest, elle est déclarée avec android:maxSdkVersion="30", donc
    // sur Android 12+ elle n'existe plus pour le système : la demander
    // renvoie "denied" en permanence et bloquait à tort tout l'appareil.
    // Sur Android <12 c'est une permission "normale", accordée
    // automatiquement à l'installation — inutile de la demander au runtime.
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    // Sur Android <12, bluetoothConnect/bluetoothScan n'existent pas et
    // remontent "permanentlyDenied" ou "restricted" sans bloquer : on se
    // base donc sur le fait qu'aucune des permissions pertinentes ne soit
    // explicitement refusée par l'utilisateur.
    final connect = statuses[Permission.bluetoothConnect];
    final scan = statuses[Permission.bluetoothScan];

    final connectOk = connect == null || connect.isGranted || connect.isLimited;
    final scanOk = scan == null || scan.isGranted || scan.isLimited;

    return connectOk && scanOk;
  }

  /// Vrai si l'utilisateur a définitivement refusé (via "Ne plus demander"),
  /// auquel cas il faut le renvoyer vers les paramètres de l'app.
  Future<bool> isPermanentlyDenied() async {
    final connect = await Permission.bluetoothConnect.status;
    final scan = await Permission.bluetoothScan.status;
    return connect.isPermanentlyDenied || scan.isPermanentlyDenied;
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (_) {
      return [];
    }
  }

  Future<bool> get isConnected async {
    try {
      return await PrintBluetoothThermal.connectionStatus
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect(String macAddress) async {
    // Certaines imprimantes thermiques bon marché (confirmé avec le modèle
    // 2Connet) échouent systématiquement au premier essai de connexion
    // ("read failed, socket might closed or timeout") mais réussissent
    // presque immédiatement au second essai. On réessaie donc une fois
    // avant d'abandonner.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final ok = await PrintBluetoothThermal.connect(
                macPrinterAddress: macAddress)
            .timeout(const Duration(seconds: 8), onTimeout: () => false);
        if (ok) return true;
      } catch (_) {
        // On retente au tour suivant.
      }
      if (attempt == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
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
      final storeName = await _db.getSetting('storeName');
      final storeAddress = await _db.getSetting('storeAddress');
      final storePhone = await _db.getSetting('storePhone');

      final lines = <String>[];
      lines.add((storeName == null || storeName.trim().isEmpty)
          ? 'FAFOUTT STORE'
          : storeName.toUpperCase());
      lines.add('Point de Vente');
      if (storeAddress != null && storeAddress.isNotEmpty) {
        lines.add(storeAddress);
      }
      if (storePhone != null && storePhone.isNotEmpty) {
        lines.add('Tél : $storePhone');
      }
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
        ).timeout(const Duration(seconds: 3), onTimeout: () => false);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
