import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cash_closing.dart';
import '../providers/session_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
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
    final lang = context.read<LocaleProvider>().language;
    final employee = context.read<SessionProvider>().currentEmployee;
    if (employee == null) return;

    if (_countedController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'cash_closing_missing_amount')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(lang, 'cash_closing_confirm_title')),
        content: Text(
          _difference == 0
              ? tr(lang, 'cash_closing_balanced_msg')
              : _difference > 0
                  ? '${tr(lang, 'cash_closing_surplus_msg')} ${_currencyFormat.format(_difference)} ${tr(lang, 'cash_closing_vs_expected')}'
                  : '${tr(lang, 'cash_closing_shortage_msg')} ${_currencyFormat.format(_difference.abs())} ${tr(lang, 'cash_closing_vs_expected')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(lang, 'common_cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(lang, 'cash_closing_confirm_button')),
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
        SnackBar(
          content: Text(tr(lang, 'cash_closing_saved')),
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
    final lang = context.watch<LocaleProvider>().language;
    return Scaffold(
      appBar: AppBar(
        title: FafouttHeader(subtitle: tr(lang, 'cash_closing_subtitle')),
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
                        ? '${tr(lang, 'cash_closing_period_since')} (${_dateFormat.format(_lastClosingDate!)})'
                        : tr(lang, 'cash_closing_period_today'),
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
                              Text(tr(lang, 'cash_closing_expected'),
                                  style: const TextStyle(
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
                    decoration: InputDecoration(
                        labelText: tr(lang, 'cash_closing_counted_label')),
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
                                ? tr(lang, 'cash_closing_balanced')
                                : _difference > 0
                                    ? tr(lang, 'cash_closing_surplus')
                                    : tr(lang, 'cash_closing_shortage'),
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
                    decoration: InputDecoration(
                        labelText: tr(lang, 'cash_closing_note')),
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
                          : Text(tr(lang, 'cash_closing_save_button')),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(tr(lang, 'cash_closing_history'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(tr(lang, 'cash_closing_no_history'),
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
                                '${c.employeeName} · ${tr(lang, 'cash_closing_expected_short')} ${_currencyFormat.format(c.expectedCash)} · ${tr(lang, 'cash_closing_counted_short')} ${_currencyFormat.format(c.countedCash)}'),
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
