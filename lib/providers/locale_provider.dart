import 'package:flutter/material.dart';
import '../services/database_service.dart';

class LocaleProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  String _language = 'fr';

  String get language => _language;

  Future<void> load() async {
    final saved = await _db.getSetting('appLanguage');
    if (saved != null && saved.isNotEmpty) {
      _language = saved;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _db.setSetting('appLanguage', language);
    notifyListeners();
  }
}
