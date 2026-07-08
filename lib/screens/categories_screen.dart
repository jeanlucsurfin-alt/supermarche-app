import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../theme/app_theme.dart';
import '../utils/category_style.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Future<void> _openAddDialog() async {
    final lang = context.read<LocaleProvider>().language;
    final nameController = TextEditingController();
    String selectedIcon = categoryIconChoices.keys.first;
    int selectedColor = categoryColorChoices.first;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr(lang, 'categories_new')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: tr(lang, 'categories_name')),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(tr(lang, 'categories_icon'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryIconChoices.entries.map((entry) {
                    final selected = entry.key == selectedIcon;
                    return InkWell(
                      onTap: () =>
                          setDialogState(() => selectedIcon = entry.key),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(selectedColor).withOpacity(0.15)
                              : const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: Color(selectedColor), width: 1.5)
                              : null,
                        ),
                        child: Icon(entry.value,
                            size: 18,
                            color: selected
                                ? Color(selectedColor)
                                : AppColors.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(tr(lang, 'categories_color'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryColorChoices.map((colorValue) {
                    final selected = colorValue == selectedColor;
                    return InkWell(
                      onTap: () =>
                          setDialogState(() => selectedColor = colorValue),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: AppColors.textPrimary, width: 2)
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(lang, 'common_cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  await context.read<CategoryProvider>().addCategory(
                        nameController.text.trim(),
                        selectedIcon,
                        selectedColor,
                      );
                  if (context.mounted) Navigator.pop(context);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr(lang, 'categories_already_exists')),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              child: Text(tr(lang, 'common_add')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id, String name) async {
    final lang = context.read<LocaleProvider>().language;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(lang, 'categories_delete_title')),
        content: Text('"$name" ${tr(lang, 'categories_delete_content')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(lang, 'common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text(tr(lang, 'common_delete'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<CategoryProvider>().deleteCategory(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(lang, 'categories_title')),
      ),
      body: categories.isEmpty
          ? Center(
              child: Text(tr(lang, 'categories_empty'),
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(category.colorValue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(iconForKey(category.iconKey),
                          color: Colors.white, size: 18),
                    ),
                    title: Text(category.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () =>
                          _confirmDelete(category.id!, category.name),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        onPressed: _openAddDialog,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr(lang, 'common_add')),
      ),
    );
  }
}
