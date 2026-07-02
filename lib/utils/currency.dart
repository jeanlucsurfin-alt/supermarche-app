import 'package:intl/intl.dart';

final NumberFormat _htgFormat =
    NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);

final NumberFormat _usdFormat =
    NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);

/// Formate un montant en HTG avec une espace insécable pour éviter
/// que le nombre se coupe sur deux lignes dans les petites cartes.
String formatHTG(num amount) {
  return _htgFormat.format(amount).replaceAll(' ', '\u00A0');
}

/// Formate un montant en USD.
String formatUSD(num amount) {
  return _usdFormat.format(amount).replaceAll(' ', '\u00A0');
}

/// Formate un montant selon la devise sélectionnée ('HTG' ou 'USD').
String formatPrice(num amount, String currency) {
  return currency == 'USD' ? formatUSD(amount) : formatHTG(amount);
}

/// Version sans espace insécable, pour les documents PDF dont la police
/// peut ne pas supporter ce caractère Unicode.
String formatPricePlain(num amount, String currency) {
  return currency == 'USD' ? _usdFormat.format(amount) : _htgFormat.format(amount);
}
