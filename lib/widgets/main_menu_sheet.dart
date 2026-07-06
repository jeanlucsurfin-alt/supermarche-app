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
import '../screens/promotions_screen.dart';

/// Ouvre le menu principal (gestion + déconnexion) juste en-dessous du
/// widget identifié par [anchorKey] — typiquement le logo "F" de l'en-tête.
Future<void> showMainMenu(GlobalKey anchorKey) async {
  final anchorContext = anchorKey.currentContext;
  if (anchorContext == null) return;

  final RenderBox anchorBox = anchorContext.findRenderObject() as RenderBox;
  final overlay =
      Overlay.of(anchorContext).context.findRenderObject() as RenderBox;

  final topLeft =
      anchorBox.localToGlobal(Offset(0, anchorBox.size.height + 8), ancestor: overlay);
  final bottomRight =
      anchorBox.localToGlobal(anchorBox.size.bottomRight(Offset.zero), ancestor: overlay);

  final position = RelativeRect.fromRect(
    Rect.fromPoints(topLeft, bottomRight),
    Offset.zero & overlay.size,
  );

  final value = await showMenu<String>(
    context: anchorContext,
    position: position,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    items: [
      _item(Icons.badge_outlined, 'Employés', 'employes'),
      _item(Icons.people_outline_rounded, 'Clients', 'clients'),
      _item(Icons.schedule_rounded, 'Créances', 'creances'),
      _item(Icons.settings_outlined, 'Paramètres', 'parametres'),
      _item(Icons.point_of_sale_rounded, 'Clôture de caisse', 'cloture'),
      _item(Icons.undo_rounded, 'Retours', 'retours'),
      _item(Icons.trending_down_rounded, 'Dépenses', 'depenses'),
      _item(Icons.local_offer_outlined, 'Promotions', 'promotions'),
      _item(Icons.history_rounded, 'Journal d\'activité', 'journal'),
      const PopupMenuDivider(height: 8),
      _item(Icons.logout_rounded, 'Déconnexion', 'logout', color: AppColors.danger),
    ],
  );

  if (value == null || !anchorContext.mounted) return;

  if (value == 'logout') {
    await _confirmLogout(anchorContext);
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
    case 'promotions':
      screen = const PromotionsScreen();
      break;
    case 'journal':
      screen = const ActivityLogScreen();
      break;
  }

  if (screen != null && anchorContext.mounted) {
    await Navigator.push(
      anchorContext,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }
}

PopupMenuItem<String> _item(IconData icon, String label, String value,
    {Color? color}) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.navy),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );
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
