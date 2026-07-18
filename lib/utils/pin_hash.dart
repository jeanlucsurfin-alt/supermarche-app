import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Hachage des codes PIN employés (SHA-256 + sel aléatoire par employé).
///
/// Le PIN stocké en base a le format "sel:empreinte" (les deux en
/// hexadécimal/base64url), au lieu du PIN en clair. Comme il s'agit d'un
/// hachage à sens unique, le PIN d'origine ne peut plus jamais être
/// retrouvé ou affiché — seule une vérification (le PIN saisi produit-il
/// la même empreinte ?) est possible.
class PinHash {
  static const _separator = ':';

  /// Génère un sel aléatoire et retourne "sel:empreinte", prêt à stocker
  /// dans la colonne `pin`.
  static String hash(String pin) {
    final salt = _generateSalt();
    final digest = _digest(pin, salt);
    return '$salt$_separator$digest';
  }

  /// Vérifie qu'un PIN saisi correspond à la valeur stockée.
  ///
  /// Gère aussi, en repli, une ancienne valeur encore en clair (non
  /// migrée) : utile uniquement pendant la transition, jamais après une
  /// migration complète de la base.
  static bool verify(String enteredPin, String stored) {
    if (!stored.contains(_separator)) {
      return enteredPin == stored;
    }
    final sepIndex = stored.indexOf(_separator);
    final salt = stored.substring(0, sepIndex);
    final expectedDigest = stored.substring(sepIndex + 1);
    return _digest(enteredPin, salt) == expectedDigest;
  }

  /// Vrai si la valeur stockée est déjà au format haché (sel:empreinte)
  /// plutôt qu'un PIN en clair — utile pour la migration.
  static bool isHashed(String stored) => stored.contains(_separator);

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _digest(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }
}
