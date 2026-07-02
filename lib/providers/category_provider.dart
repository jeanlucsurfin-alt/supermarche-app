import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../utils/category_style.dart';
import '../theme/app_theme.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Category> _categories = [];

  List<Category> get categories => _categories;
  List<String> get names => _categories.map((c) => c.name).toList();

  Future<void> load() async {
    _categories = await _db.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name, String iconKey, int colorValue) async {
    await _db.insertCategory(Category(
      name: name,
      iconKey: iconKey,
      colorValue: colorValue,
    ));
    await load();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await load();
  }

  IconData iconFor(String name) {
    final match = _categories.where((c) => c.name == name);
    if (match.isEmpty) return Icons.inventory_2_rounded;
    return iconForKey(match.first.iconKey);
  }

  Color colorFor(String name) {
    final match = _categories.where((c) => c.name == name);
    if (match.isEmpty) return AppColors.navy;
    return Color(match.first.colorValue);
  }
}
