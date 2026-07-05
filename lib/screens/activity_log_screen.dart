import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_log.dart';
import '../models/employee.dart';
import '../providers/session_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.watch<SessionProvider>().currentEmployee?.role ==
            EmployeeRole.admin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journal d\'activité')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text('Accès réservé aux administrateurs',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Journal d\'activité')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text('Aucune activité enregistrée',
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
                              color: AppColors.navy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(_actionIcon(log.action),
                                color: AppColors.navy, size: 18),
                          ),
                          title: Text(log.action,
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
