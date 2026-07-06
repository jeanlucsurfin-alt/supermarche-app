import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/session_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final DatabaseService _db = DatabaseService();
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customers = await _db.getAllCustomers();
    setState(() {
      _customers = customers;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _customers.where((c) {
        return query.isEmpty ||
            c.name.toLowerCase().contains(query) ||
            c.phone.contains(query);
      }).toList();
    });
  }

  Future<void> _openEditDialog({Customer? customer}) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Nouveau client' : 'Modifier le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nom et téléphone sont obligatoires'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              final newCustomer = Customer(
                id: customer?.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                loyaltyPoints: customer?.loyaltyPoints ?? 0,
              );
              if (customer == null) {
                await _db.insertCustomer(newCustomer);
              } else {
                await _db.updateCustomer(newCustomer);
              }
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(customer == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        content: Text('${customer.name} sera retiré de la liste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteCustomer(customer.id!);
      final employee = context.mounted
          ? context.read<SessionProvider>().currentEmployee
          : null;
      await _db.logActivity(
        employeeId: employee?.id,
        employeeName: employee?.name ?? 'Inconnu',
        action: 'Suppression client',
        description: '${customer.name} (${customer.phone})',
      );
      _load();
    }
  }

  Future<void> _openHistory(Customer customer) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerHistorySheet(customer: customer, db: _db),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un client ou un numéro...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('Aucun client enregistré',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final customer = _filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _openHistory(customer),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.navy.withOpacity(0.1),
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(customer.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(customer.phone,
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 14, color: AppColors.gold),
                                    const SizedBox(width: 3),
                                    Text('${customer.loyaltyPoints}',
                                        style: const TextStyle(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.textSecondary, size: 20),
                                onPressed: () => _confirmDelete(customer),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        onPressed: () => _openEditDialog(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _CustomerHistorySheet extends StatefulWidget {
  final Customer customer;
  final DatabaseService db;
  const _CustomerHistorySheet({required this.customer, required this.db});

  @override
  State<_CustomerHistorySheet> createState() => _CustomerHistorySheetState();
}

class _CustomerHistorySheetState extends State<_CustomerHistorySheet> {
  List<Map<String, dynamic>> _sales = [];
  double _creditBalance = 0;
  bool _loading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sales = await widget.db.getSalesForCustomer(widget.customer.id!);
    final balance =
        await widget.db.getOutstandingBalanceForCustomer(widget.customer.id!);
    setState(() {
      _sales = sales;
      _creditBalance = balance;
      _loading = false;
    });
  }

  double get _totalSpent =>
      _sales.fold(0.0, (sum, s) => sum + (s['total'] as double));

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6EC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(widget.customer.phone,
                            style:
                                const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              icon: Icons.star_rounded,
                              label:
                                  '${widget.customer.loyaltyPoints} points',
                              color: AppColors.gold,
                            ),
                            _StatChip(
                              icon: Icons.receipt_long_rounded,
                              label: '${_sales.length} achats',
                              color: AppColors.blue,
                            ),
                            _StatChip(
                              icon: Icons.payments_rounded,
                              label: _currencyFormat
                                  .format(_totalSpent)
                                  .replaceAll(' ', '\u00A0'),
                              color: AppColors.success,
                            ),
                            if (_creditBalance > 0)
                              _StatChip(
                                icon: Icons.schedule_rounded,
                                label: 'Doit ${_currencyFormat.format(_creditBalance).replaceAll(' ', '\u00A0')}',
                                color: AppColors.danger,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: _sales.isEmpty
                        ? Center(
                            child: Text('Aucun achat enregistré',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _sales.length,
                            itemBuilder: (context, index) {
                              final sale = _sales[index];
                              final date = DateTime.parse(sale['date']);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shopping_bag_outlined,
                                        size: 18, color: AppColors.navy),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(_dateFormat.format(date),
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                    Text(
                                      _currencyFormat
                                          .format(sale['total'])
                                          .replaceAll(' ', '\u00A0'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}
