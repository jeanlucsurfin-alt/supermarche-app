import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  Employee? _currentEmployee;

  Employee? get currentEmployee => _currentEmployee;
  bool get isLoggedIn => _currentEmployee != null;

  /// Tente de connecter un employé à partir de son PIN.
  /// Retourne true si succès.
  Future<bool> login(String pin) async {
    final employees = await _db.getAllEmployees();
    final match = employees.where((e) => e.pin == pin);
    if (match.isEmpty) return false;

    _currentEmployee = match.first;

    // Pointage automatique de l'arrivée si aucun pointage actif.
    final active = await _db.getActiveShift(_currentEmployee!.id!);
    if (active == null) {
      await _db.clockIn(_currentEmployee!.id!, _currentEmployee!.name);
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (_currentEmployee != null) {
      final active = await _db.getActiveShift(_currentEmployee!.id!);
      if (active != null) {
        await _db.clockOut(active.id!);
      }
    }
    _currentEmployee = null;
    notifyListeners();
  }
}
