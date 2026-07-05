import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee_shift.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';
import '../widgets/main_menu_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final int refreshTrigger;
  const DashboardScreen({
    super.key,
    required this.onNavigate,
    this.refreshTrigger = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  bool _loading = true;
  double _todayRevenue = 0;
  int _todayTransactions = 0;
  int _lowStockCount = 0;
  double _outstandingCredit = 0;
  double _todayExpenses = 0;
  double _todayNetProfit = 0;
  List<EmployeeShift> _activeShifts = [];

  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharge les données à chaque fois qu'on revient sur cet onglet.
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final summary = await _db.getSalesSummary(startOfDay, now);
    final products = await _db.getAllProducts();
    final outstanding = await _db.getTotalOutstandingCredit();
    final shifts = await _db.getActiveShifts();

    setState(() {
      _todayRevenue = summary['revenue'] ?? 0;
      _todayTransactions = (summary['transactionCount'] ?? 0).toInt();
      _lowStockCount = products.where((p) => p.isLowStock).length;
      _outstandingCredit = outstanding;
      _todayExpenses = summary['totalExpenses'] ?? 0;
      _todayNetProfit = summary['netProfit'] ?? 0;
      _activeShifts = shifts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FafouttHeader(
          subtitle: 'Tableau de bord',
          onTap: () => showMainMenu(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Aujourd\'hui',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardCard(
                          icon: Icons.payments_rounded,
                          label: 'Ventes du jour',
                          value: _currencyFormat.format(_todayRevenue),
                          subLabel: '$_todayTransactions vente(s)',
                          color: AppColors.navy,
                          onTap: () => widget.onNavigate(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardCard(
                          icon: Icons.inventory_2_rounded,
                          label: 'Stock bas',
                          value: '$_lowStockCount',
                          subLabel: _lowStockCount > 0
                              ? 'à réapprovisionner'
                              : 'tout est en ordre',
                          color: _lowStockCount > 0
                              ? AppColors.danger
                              : AppColors.success,
                          onTap: () => widget.onNavigate(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardCard(
                          icon: Icons.schedule_rounded,
                          label: 'Créances en cours',
                          value: _currencyFormat.format(_outstandingCredit),
                          subLabel: 'toutes périodes',
                          color: AppColors.danger,
                          onTap: () => widget.onNavigate(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardCard(
                          icon: Icons.badge_rounded,
                          label: 'En service',
                          value: '${_activeShifts.length}',
                          subLabel: 'employé(s)',
                          color: AppColors.success,
                          onTap: () => widget.onNavigate(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardCard(
                          icon: Icons.money_off_rounded,
                          label: 'Dépenses du jour',
                          value: _currencyFormat.format(_todayExpenses),
                          subLabel: 'aujourd\'hui',
                          color: AppColors.danger,
                          onTap: () => widget.onNavigate(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardCard(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Bénéfice net du jour',
                          value: _currencyFormat.format(_todayNetProfit),
                          subLabel: 'ventes - dépenses',
                          color: _todayNetProfit >= 0
                              ? AppColors.success
                              : AppColors.danger,
                          onTap: () => widget.onNavigate(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_activeShifts.isNotEmpty) ...[
                    Text('Employés en service',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ..._activeShifts.map((shift) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.success.withOpacity(0.1),
                              child: Text(
                                shift.employeeName.isNotEmpty
                                    ? shift.employeeName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(shift.employeeName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'Depuis ${DateFormat('HH:mm').format(shift.clockIn)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],
                  Text('Accès rapide',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickAccessChip(
                        icon: Icons.point_of_sale_rounded,
                        label: 'Vente',
                        onTap: () => widget.onNavigate(1),
                      ),
                      _QuickAccessChip(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stocks',
                        onTap: () => widget.onNavigate(2),
                      ),
                      _QuickAccessChip(
                        icon: Icons.bar_chart_rounded,
                        label: 'Rapports',
                        onTap: () => widget.onNavigate(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subLabel;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.textPrimary),
                ),
              ),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Text(subLabel,
                  style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3E6EC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.navy),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
