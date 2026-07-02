import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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

  final _screens = const [
    PosScreen(),
    StockScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
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
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          height: 62,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.point_of_sale_rounded, color: AppColors.navy),
              label: 'Vente',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.navy),
              label: 'Stocks',
            ),
            NavigationDestination(
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
