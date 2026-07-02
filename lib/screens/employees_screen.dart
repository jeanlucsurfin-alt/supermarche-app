import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/employee_shift.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final DatabaseService _db = DatabaseService();
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employees = await _db.getAllEmployees();
    setState(() => _employees = employees);
  }

  Color _roleColor(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.admin:
        return AppColors.danger;
      case EmployeeRole.gerant:
        return AppColors.gold;
      case EmployeeRole.caissier:
        return AppColors.blue;
    }
  }

  Future<void> _openEditDialog({Employee? employee}) async {
    final nameController = TextEditingController(text: employee?.name ?? '');
    final pinController = TextEditingController(text: employee?.pin ?? '');
    EmployeeRole selectedRole = employee?.role ?? EmployeeRole.caissier;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(employee == null ? 'Nouvel employé' : 'Modifier l\'employé'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EmployeeRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: EmployeeRole.values
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedRole = v ?? selectedRole),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                    labelText: 'Code PIN (4 chiffres)'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    pinController.text.trim().length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Nom requis et PIN à 4 chiffres obligatoire'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                final newEmployee = Employee(
                  id: employee?.id,
                  name: nameController.text.trim(),
                  role: selectedRole,
                  pin: pinController.text.trim(),
                );
                if (employee == null) {
                  await _db.insertEmployee(newEmployee);
                } else {
                  await _db.updateEmployee(newEmployee);
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(employee == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet employé ?'),
        content: Text('${employee.name} sera retiré de la liste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteEmployee(employee.id!);
      _load();
    }
  }

  Future<void> _openShiftSheet(Employee employee) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShiftSheet(employee: employee, db: _db),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employés'),
      ),
      body: _employees.isEmpty
          ? Center(
              child: Text('Aucun employé enregistré',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                final roleColor = _roleColor(employee.role);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => _openShiftSheet(employee),
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withOpacity(0.12),
                      child: Text(
                        employee.name.isNotEmpty
                            ? employee.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: roleColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(employee.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        employee.role.label,
                        style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    isThreeLine: false,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppColors.textSecondary, size: 20),
                          onPressed: () =>
                              _openEditDialog(employee: employee),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textSecondary, size: 20),
                          onPressed: () => _confirmDelete(employee),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditDialog(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _ShiftSheet extends StatefulWidget {
  final Employee employee;
  final DatabaseService db;
  const _ShiftSheet({required this.employee, required this.db});

  @override
  State<_ShiftSheet> createState() => _ShiftSheetState();
}

class _ShiftSheetState extends State<_ShiftSheet> {
  EmployeeShift? _activeShift;
  List<EmployeeShift> _history = [];
  bool _loading = true;
  final _timeFormat = DateFormat('dd/MM HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = await widget.db.getActiveShift(widget.employee.id!);
    final history = await widget.db.getShiftsForEmployee(widget.employee.id!);
    setState(() {
      _activeShift = active;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _toggleClock() async {
    if (_activeShift != null) {
      await widget.db.clockOut(_activeShift!.id!);
    } else {
      await widget.db.clockIn(widget.employee.id!, widget.employee.name);
    }
    _load();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6EC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(widget.employee.name,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(widget.employee.role.label,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                if (_activeShift != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'En service depuis ${_timeFormat.format(_activeShift!.clockIn)}',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeShift != null
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                    icon: Icon(_activeShift != null
                        ? Icons.logout_rounded
                        : Icons.login_rounded),
                    onPressed: _toggleClock,
                    label: Text(_activeShift != null
                        ? 'POINTER LE DÉPART'
                        : 'POINTER L\'ARRIVÉE'),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Historique récent',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Aucun pointage enregistré',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final shift = _history[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                shift.isActive
                                    ? Icons.play_circle_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 16,
                                color: shift.isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_timeFormat.format(shift.clockIn)} → ${shift.clockOut != null ? _timeFormat.format(shift.clockOut!) : 'en cours'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                _formatDuration(shift.duration),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
