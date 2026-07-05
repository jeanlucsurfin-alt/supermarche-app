import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/session_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'reports_screen.dart';
import 'stock_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _lowStockCount = 0;
  int _dashboardRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadLowStockCount();
    DatabaseService().performAutoBackupIfDue();
  }

  Future<void> _loadLowStockCount() async {
    final products = await DatabaseService().getAllProducts();
    final count = products.where((p) => p.isLowStock).length;
    if (mounted) setState(() => _lowStockCount = count);
  }

  void _navigateTo(int index) {
    setState(() {
      _index = index;
      if (index == 0) _dashboardRefreshCounter++;
    });
    if (index == 2) _loadLowStockCount();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final role = session.currentEmployee?.role ?? EmployeeRole.caissier;
    final isCashierOnly = role == EmployeeRole.caissier;

    // Un caissier n'a accès qu'au module Vente, sans tableau de bord.
    if (isCashierOnly) {
      return const PosScreen();
    }

    final screens = [
      DashboardScreen(
        onNavigate: _navigateTo,
        refreshTrigger: _dashboardRefreshCounter,
      ),
      const PosScreen(),
      const StockScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.navy.withOpacity(0.1),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.navy : AppColors.textSecondary,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _navigateTo,
          backgroundColor: Colors.white,
          height: 62,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.navy),
              label: 'Accueil',
            ),
            const NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.point_of_sale_rounded, color: AppColors.navy),
              label: 'Vente',
            ),
            NavigationDestination(
              icon: _lowStockCount > 0
                  ? Badge(
                      label: Text('$_lowStockCount'),
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.textSecondary),
                    )
                  : const Icon(Icons.inventory_2_outlined,
                      color: AppColors.textSecondary),
              selectedIcon: _lowStockCount > 0
                  ? Badge(
                      label: Text('$_lowStockCount'),
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.inventory_2_rounded, color: AppColors.navy),
                    )
                  : const Icon(Icons.inventory_2_rounded, color: AppColors.navy),
              label: 'Stocks',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.navy),
              label: 'Rapports',
            ),
          ],
        ),
      ),
    );
  }
}
