import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_log.dart';
import '../models/employee.dart';
import '../providers/session_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final DatabaseService _db = DatabaseService();
  List<ActivityLog> _logs = [];
  bool _loading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _db.getActivityLogs();
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  IconData _actionIcon(String action) {
    if (action.contains('Suppression')) return Icons.delete_outline;
    if (action.contains('Modification')) return Icons.edit_outlined;
    if (action.contains('Retour') || action.contains('Annulation')) {
      return Icons.undo_rounded;
    }
    return Icons.history_rounded;
  }

  /// Les actions sont enregistrées en français dans la base (pour rester
  /// cohérentes dans le temps), mais on les affiche traduites à l'écran.
  String _translatedAction(String action, String lang) {
    switch (action) {
      case 'Suppression produit':
        return tr(lang, 'activity_action_delete_product');
      case 'Modification prix':
        return tr(lang, 'activity_action_price_change');
      case 'Suppression employé':
        return tr(lang, 'activity_action_delete_employee');
      case 'Suppression client':
        return tr(lang, 'activity_action_delete_customer');
      case 'Retour vente':
        return tr(lang, 'activity_action_return');
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().language;
    final isAdmin =
        context.watch<SessionProvider>().currentEmployee?.role ==
            EmployeeRole.admin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(lang, 'activity_title'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(tr(lang, 'activity_restricted'),
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'activity_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text(tr(lang, 'activity_empty'),
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(_actionIcon(log.action),
                                color: Colors.white, size: 18),
                          ),
                          title: Text(_translatedAction(log.action, lang),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${log.description}\n${log.employeeName} · ${_dateFormat.format(log.date)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
