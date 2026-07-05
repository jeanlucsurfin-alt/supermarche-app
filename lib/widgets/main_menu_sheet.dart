import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../screens/employees_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/credit_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/cash_closing_screen.dart';
import '../screens/returns_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/activity_log_screen.dart';

/// Ouvre le menu principal (gestion + déconnexion), accessible en touchant
/// le logo "F" de Fafoutt Store dans l'en-tête des écrans principaux.
Future<void> showMainMenu(BuildContext context) async {
  final value = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const _MenuTile(
              icon: Icons.badge_outlined, label: 'Employés', value: 'employes'),
          const _MenuTile(
              icon: Icons.people_outline_rounded,
              label: 'Clients',
              value: 'clients'),
          const _MenuTile(
              icon: Icons.schedule_rounded,
              label: 'Créances',
              value: 'creances'),
          const _MenuTile(
              icon: Icons.settings_outlined,
              label: 'Paramètres',
              value: 'parametres'),
          const _MenuTile(
              icon: Icons.point_of_sale_rounded,
              label: 'Clôture de caisse',
              value: 'cloture'),
          const _MenuTile(
              icon: Icons.undo_rounded, label: 'Retours', value: 'retours'),
          const _MenuTile(
              icon: Icons.trending_down_rounded,
              label: 'Dépenses',
              value: 'depenses'),
          const _MenuTile(
              icon: Icons.history_rounded,
              label: 'Journal d\'activité',
              value: 'journal'),
          const Divider(height: 16),
          const _MenuTile(
              icon: Icons.logout_rounded,
              label: 'Déconnexion',
              value: 'logout',
              color: AppColors.danger),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (value == null || !context.mounted) return;

  if (value == 'logout') {
    await _confirmLogout(context);
    return;
  }

  Widget? screen;
  switch (value) {
    case 'employes':
      screen = const EmployeesScreen();
      break;
    case 'clients':
      screen = const CustomersScreen();
      break;
    case 'creances':
      screen = const CreditScreen();
      break;
    case 'parametres':
      screen = const SettingsScreen();
      break;
    case 'cloture':
      screen = const CashClosingScreen();
      break;
    case 'retours':
      screen = const ReturnsScreen();
      break;
    case 'depenses':
      screen = const ExpensesScreen();
      break;
    case 'journal':
      screen = const ActivityLogScreen();
      break;
  }

  if (screen != null && context.mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  final session = context.read<SessionProvider>();
  final name = session.currentEmployee?.name ?? '';
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Se déconnecter ?'),
      content:
          Text('$name sera déconnecté(e). Le pointage sera clôturé automatiquement.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Déconnexion', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await session.logout();
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.navy, size: 20),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
