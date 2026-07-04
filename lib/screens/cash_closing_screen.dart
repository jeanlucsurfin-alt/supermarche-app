import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cash_closing.dart';
import '../providers/session_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';
import '../widgets/logout_button.dart';

class CashClosingScreen extends StatefulWidget {
  const CashClosingScreen({super.key});

  @override
  State<CashClosingScreen> createState() => _CashClosingScreenState();
}

class _CashClosingScreenState extends State<CashClosingScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _countedController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  double _expectedCash = 0;
  DateTime? _lastClosingDate;
  List<CashClosing> _history = [];
  bool _loading = true;
  bool _saving = false;

  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final expected = await _db.getExpectedCashSinceLastClosing();
    final lastDate = await _db.getLastClosingDate();
    final history = await _db.getCashClosingHistory();
    setState(() {
      _expectedCash = expected;
      _lastClosingDate = lastDate;
      _history = history;
      _loading = false;
    });
  }

  double get _countedCash => double.tryParse(_countedController.text) ?? 0;
  double get _difference => _countedCash - _expectedCash;

  Future<void> _confirmClosing() async {
    final employee = context.read<SessionProvider>().currentEmployee;
    if (employee == null) return;

    if (_countedController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez le montant compté en caisse'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la clôture ?'),
        content: Text(
          _difference == 0
              ? 'La caisse est parfaitement équilibrée.'
              : _difference > 0
                  ? 'Excédent de ${_currencyFormat.format(_difference)} par rapport au calcul attendu.'
                  : 'Manque de ${_currencyFormat.format(_difference.abs())} par rapport au calcul attendu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    await _db.insertCashClosing(CashClosing(
      employeeId: employee.id!,
      employeeName: employee.name,
      expectedCash: _expectedCash,
      countedCash: _countedCash,
      date: DateTime.now(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    ));

    _countedController.clear();
    _noteController.clear();
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clôture enregistrée'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    _load();
  }

  Color _diffColor(double diff) {
    if (diff == 0) return AppColors.success;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FafouttHeader(subtitle: 'Clôture de caisse'),
        actions: const [LogoutButton(), SizedBox(width: 4)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    _lastClosingDate != null
                        ? 'Période comptée depuis la dernière clôture (${_dateFormat.format(_lastClosingDate!)})'
                        : 'Période comptée depuis le début de la journée',
                    style:
                        const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Montant attendu (ventes cash)',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              Text(
                                _currencyFormat.format(_expectedCash),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _countedController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Montant compté en caisse (HTG)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (_countedController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _diffColor(_difference).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _difference == 0
                                ? 'Caisse équilibrée'
                                : _difference > 0
                                    ? 'Excédent'
                                    : 'Manquant',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _diffColor(_difference)),
                          ),
                          Text(
                            _currencyFormat.format(_difference.abs()),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: _diffColor(_difference)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                        labelText: 'Note (optionnel, ex : explication d\'écart)'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _confirmClosing,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('ENREGISTRER LA CLÔTURE'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Historique des clôtures',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Aucune clôture enregistrée',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ..._history.map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              c.difference == 0
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.warning_amber_rounded,
                              color: _diffColor(c.difference),
                            ),
                            title: Text(_dateFormat.format(c.date)),
                            subtitle: Text(
                                '${c.employeeName} · Attendu ${_currencyFormat.format(c.expectedCash)} · Compté ${_currencyFormat.format(c.countedCash)}'),
                            trailing: Text(
                              (c.difference >= 0 ? '+' : '') +
                                  _currencyFormat.format(c.difference),
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _diffColor(c.difference)),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
