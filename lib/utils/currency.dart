import 'package:intl/intl.dart';

final NumberFormat _htgFormat =
    NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);

/// Formate un montant en HTG avec une espace insécable pour éviter
/// que le nombre se coupe sur deux lignes dans les petites cartes.
String formatHTG(num amount) {
  return _htgFormat.format(amount).replaceAll(' ', '\u00A0');
}
