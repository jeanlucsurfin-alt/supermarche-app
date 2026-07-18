import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../utils/currency.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final DatabaseService _db = DatabaseService();

  // Connexion active maintenue en mémoire. flutter_bluetooth_serial gère la
  // connexion sur un thread natif en arrière-plan (contrairement à
  // print_bluetooth_thermal, qui bloquait le thread principal et causait
  // des gels de l'app/ANR quand l'imprimante ne répondait pas au premier
  // essai).
  BluetoothConnection? _connection;

  // Dernière raison d'échec détaillée, pour affichage/diagnostic côté UI.
  String? lastError;

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

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance
          .getBondedDevices()
          .timeout(const Duration(seconds: 6), onTimeout: () => []);
    } catch (_) {
      return [];
    }
  }

  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Connecte à l'adresse MAC donnée. Certaines imprimantes thermiques bon
  /// marché (confirmé avec le modèle 2Connet) échouent systématiquement au
  /// premier essai ("read failed, socket might closed or timeout") mais
  /// réussissent presque immédiatement au second essai : on réessaie donc
  /// une fois avant d'abandonner.
  Future<bool> connect(String address) async {
    lastError = null;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final connection = await BluetoothConnection.toAddress(address)
            .timeout(const Duration(seconds: 8));
        _connection = connection;
        return true;
      } catch (e) {
        lastError = 'Échec connexion (essai ${attempt + 1}) : $e';
      }
      if (attempt == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  Future<void> disconnect() async {
    try {
      await _connection?.finish().timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );
    } catch (_) {
      // Ignoré : l'imprimante était peut-être déjà déconnectée.
    } finally {
      _connection = null;
    }
  }

  /// Reconnecte systématiquement à l'imprimante enregistrée dans les
  /// paramètres. On ne réutilise pas une connexion existante : certaines
  /// imprimantes thermiques (confirmé avec le modèle 2Connet) ferment la
  /// connexion de leur côté juste après un travail d'impression, mais
  /// `BluetoothConnection.isConnected` côté téléphone ne détecte pas
  /// toujours cette fermeture à distance — réutiliser l'ancienne connexion
  /// écrivait alors dans le vide, sans erreur ni impression, sur les
  /// tentatives suivantes.
  Future<bool> ensureConnectedToSavedPrinter() async {
    if (_connection != null) {
      await disconnect();
    }

    final address = await _db.getSetting('printerAddress');
    if (address == null || address.isEmpty) {
      lastError = 'Aucune adresse imprimante enregistrée';
      return false;
    }

    return await connect(address);
  }

  Future<bool> hasSavedPrinter() async {
    final address = await _db.getSetting('printerAddress');
    return address != null && address.isNotEmpty;
  }

  Future<void> savePrinter(BluetoothDevice device) async {
    await _db.setSetting('printerAddress', device.address);
    await _db.setSetting('printerName', device.name ?? device.address);
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
  /// Nettoie une ligne avant envoi à l'imprimante : remplace les espaces
  /// Unicode invisibles (insécable, fine insécable — utilisées par le
  /// formatage des montants comme séparateur de milliers, ex. "1 200")
  /// par une espace ASCII normale, et retire les accents français, car le
  /// codepage par défaut de l'imprimante ne les encode pas forcément —
  /// une seule ligne avec un caractère non supporté fait échouer tout
  /// l'envoi ("Contains invalid characters").
  String _sanitizeForPrinter(String input) {
    const accentMap = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ì': 'i',
      'ô': 'o', 'ö': 'o', 'ò': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
      'À': 'A', 'Â': 'A', 'Ä': 'A', 'Á': 'A',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'Î': 'I', 'Ï': 'I', 'Ì': 'I',
      'Ô': 'O', 'Ö': 'O', 'Ò': 'O',
      'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'Ç': 'C', 'Ñ': 'N',
    };
    var result = input
        .replaceAll('\u00A0', ' ') // espace insécable
        .replaceAll('\u202F', ' ') // espace fine insécable
        .replaceAll('\u2009', ' '); // espace fine
    accentMap.forEach((accented, plain) {
      result = result.replaceAll(accented, plain);
    });
    // Filet de sécurité : tout caractère restant hors ASCII imprimable
    // est remplacé par un '?' plutôt que de faire échouer l'impression.
    result = result.replaceAllMapped(
      RegExp(r'[^\x20-\x7E]'),
      (_) => '?',
    );
    return result;
  }

  Future<bool> printReceipt(Sale sale) async {
    final connected = await ensureConnectedToSavedPrinter();
    if (!connected || _connection == null) {
      lastError ??= 'Connexion Bluetooth indisponible';
      return false;
    }

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

      // Beaucoup de mini-imprimantes thermiques génériques (dont le modèle
      // "2Connet") ignorent silencieusement du texte brut envoyé sans
      // protocole : elles attendent une vraie séquence de commandes
      // ESC/POS, à commencer par une initialisation (ESC @). On génère donc
      // les octets via esc_pos_utils au lieu d'un simple encodage texte.
      final profile = await esc.CapabilityProfile.load();
      final generator = esc.Generator(esc.PaperSize.mm58, profile);
      final bytes = <int>[];
      // Note : on utilise addAll() plutôt que += ci-dessous, car
      // List.operator+ renvoie une NOUVELLE liste au lieu de muter en
      // place — bytes += ... reviendrait à réassigner bytes, impossible
      // sur une variable final (erreur de compilation rencontrée).
      bytes.addAll(generator.reset());
      for (final l in lines) {
        bytes.addAll(generator.text(_sanitizeForPrinter(l)));
      }
      bytes.addAll(generator.feed(3));

      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent
          .timeout(const Duration(seconds: 6), onTimeout: () {});

      return true;
    } catch (e) {
      lastError = 'Échec envoi des données : $e';
      return false;
    }
  }
}
