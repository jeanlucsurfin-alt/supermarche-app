import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final session = context.read<SessionProvider>();
    final name = session.currentEmployee?.name ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: Text('$name sera déconnecté(e). Le pointage sera clôturé automatiquement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await session.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: session.currentEmployee != null
          ? 'Déconnecter ${session.currentEmployee!.name}'
          : 'Déconnexion',
      onPressed: () => _confirmLogout(context),
    );
  }
}
