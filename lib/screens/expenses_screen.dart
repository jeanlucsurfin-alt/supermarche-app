import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';
import '../widgets/logout_button.dart';

const List<String> kExpenseCategories = [
  'Loyer',
  'Électricité',
  'Salaires',
  'Transport',
  'Fournitures',
  'Entretien',
  'Autre',
];

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final DatabaseService _db = DatabaseService();
  List<Expense> _expenses = [];
  bool _loading = true;
  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Les 90 derniers jours, largement suffisant pour la vue courante.
    final expenses = await _db.getExpensesInRange(
      DateTime.now().subtract(const Duration(days: 90)),
      DateTime.now(),
    );
    setState(() {
      _expenses = expenses;
      _loading = false;
    });
  }

  double get _totalExpenses =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Loyer':
        return Icons.home_work_outlined;
      case 'Électricité':
        return Icons.bolt_rounded;
      case 'Salaires':
        return Icons.groups_outlined;
      case 'Transport':
        return Icons.local_shipping_outlined;
      case 'Fournitures':
        return Icons.inventory_2_outlined;
      case 'Entretien':
        return Icons.build_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _openAddDialog() async {
    String selectedCategory = kExpenseCategories.first;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle dépense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: kExpenseCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Montant (HTG)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(_dateFormat.format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration:
                      const InputDecoration(labelText: 'Note (optionnel)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Montant invalide'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                await _db.insertExpense(Expense(
                  category: selectedCategory,
                  amount: amount,
                  date: selectedDate,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                ));
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette dépense ?'),
        content: Text(
            '${expense.category} · ${_currencyFormat.format(expense.amount)} sera supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteExpense(expense.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FafouttHeader(subtitle: 'Dépenses du magasin'),
        actions: const [LogoutButton(), SizedBox(width: 4)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.trending_down_rounded,
                              color: AppColors.danger, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total des dépenses (90 jours)',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            Text(
                              _currencyFormat.format(_totalExpenses),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Aucune dépense enregistrée',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ..._expenses.map((expense) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(_categoryIcon(expense.category),
                                  color: AppColors.navy, size: 18),
                            ),
                            title: Text(expense.category,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              expense.note != null
                                  ? '${_dateFormat.format(expense.date)} · ${expense.note}'
                                  : _dateFormat.format(expense.date),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currencyFormat.format(expense.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.danger),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.textSecondary, size: 18),
                                  onPressed: () => _confirmDelete(expense),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        onPressed: _openAddDialog,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}
