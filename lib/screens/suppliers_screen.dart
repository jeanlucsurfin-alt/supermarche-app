import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'supplier_orders_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final DatabaseService _db = DatabaseService();
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final suppliers = await _db.getAllSuppliers();
    setState(() => _suppliers = suppliers);
  }

  Future<void> _openAddDialog() async {
    final lang = context.read<LocaleProvider>().language;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(lang, 'suppliers_new')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: tr(lang, 'suppliers_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: tr(lang, 'suppliers_phone')),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration:
                  InputDecoration(labelText: tr(lang, 'suppliers_address')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(lang, 'common_cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                return;
              }
              await _db.insertSupplier(Supplier(
                name: nameController.text,
                phone: phoneController.text,
                address: addressController.text.isEmpty
                    ? null
                    : addressController.text,
              ));
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(tr(lang, 'common_add')),
          ),
        ],
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final lang = context.read<LocaleProvider>().language;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(lang, 'suppliers_delete_title')),
        content: Text(
            '${supplier.name} sera retiré de la liste. Cette action est irréversible.'),
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
      await _db.deleteSupplier(supplier.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(lang, 'suppliers_title')),
      ),
      body: _suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(tr(lang, 'suppliers_empty'),
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _suppliers.length,
              itemBuilder: (context, index) {
                final supplier = _suppliers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SupplierOrdersScreen(supplier: supplier),
                        ),
                      );
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.clay,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.local_shipping_rounded,
                          color: Colors.white, size: 18),
                    ),
                    title: Text(supplier.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      supplier.address != null
                          ? '${supplier.phone} · ${supplier.address}'
                          : supplier.phone,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textSecondary, size: 20),
                          onPressed: () => _confirmDelete(supplier),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary, size: 18),
                      ],
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
