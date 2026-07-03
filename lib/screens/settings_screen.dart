import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _storeNameController;
  late TextEditingController _storeAddressController;
  late TextEditingController _storePhoneController;
  late TextEditingController _exchangeRateController;
  bool _loyaltyEnabled = true;
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController();
    _storeAddressController = TextEditingController();
    _storePhoneController = TextEditingController();
    _exchangeRateController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final settings = await _db.getAllSettings();
    setState(() {
      _storeNameController.text = settings['storeName'] ?? 'Fafoutt Store';
      _storeAddressController.text = settings['storeAddress'] ?? '';
      _storePhoneController.text = settings['storePhone'] ?? '';
      _exchangeRateController.text = settings['exchangeRate'] ?? '130';
      _loyaltyEnabled = (settings['loyaltyEnabled'] ?? 'true') == 'true';
      final lastBackup = settings['lastBackupDate'];
      _lastBackupDate =
          (lastBackup != null && lastBackup.isNotEmpty)
              ? DateTime.tryParse(lastBackup)
              : null;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    await _db.setSetting('storeName', _storeNameController.text.trim());
    await _db.setSetting('storeAddress', _storeAddressController.text.trim());
    await _db.setSetting('storePhone', _storePhoneController.text.trim());
    await _db.setSetting(
        'exchangeRate', _exchangeRateController.text.trim().isEmpty
            ? '130'
            : _exchangeRateController.text.trim());
    await _db.setSetting('loyaltyEnabled', _loyaltyEnabled.toString());
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres enregistrés'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  bool get _needsBackupReminder {
    if (_lastBackupDate == null) return true;
    return DateTime.now().difference(_lastBackupDate!).inDays >= 7;
  }

  Future<void> _backup() async {
    try {
      final dbPath = await _db.getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Base de données introuvable');
      }
      final tempDir = await getTemporaryDirectory();
      final backupName =
          'fafoutt_store_sauvegarde_${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.db';
      final backupFile = await dbFile.copy('${tempDir.path}/$backupName');

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'Sauvegarde Fafoutt Store du ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
      );

      await _db.setSetting('lastBackupDate', DateTime.now().toIso8601String());
      if (mounted) {
        setState(() => _lastBackupDate = DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sauvegarde créée avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer une sauvegarde ?'),
        content: const Text(
            'Toutes les données actuelles (produits, ventes, clients...) seront remplacées par celles du fichier de sauvegarde. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurer',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;

      final pickedPath = result.files.single.path!;
      final dbPath = await _db.getDatabasePath();

      await _db.closeDatabase();
      await File(pickedPath).copy(dbPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sauvegarde restaurée. Redémarrez l\'application pour appliquer les changements.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la restauration : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_needsBackupReminder)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _lastBackupDate == null
                                ? 'Aucune sauvegarde n\'a encore été effectuée.'
                                : 'Dernière sauvegarde il y a plus de 7 jours.',
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text('Informations du magasin',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(labelText: 'Nom du magasin'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storeAddressController,
                  decoration: const InputDecoration(labelText: 'Adresse (optionnel)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storePhoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                Text('Devise', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _exchangeRateController,
                  decoration: const InputDecoration(
                    labelText: 'Taux de change par défaut (HTG pour 1 USD)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                Text('Fidélité', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Programme de fidélité activé'),
                  subtitle: const Text('1 point gagné par 100 HTG dépensés'),
                  value: _loyaltyEnabled,
                  activeColor: AppColors.navy,
                  onChanged: (v) => setState(() => _loyaltyEnabled = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveSettings,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('ENREGISTRER LES PARAMÈTRES'),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Sauvegarde des données',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  _lastBackupDate != null
                      ? 'Dernière sauvegarde : ${DateFormat('dd/MM/yyyy à HH:mm').format(_lastBackupDate!)}'
                      : 'Aucune sauvegarde effectuée',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _backup,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('SAUVEGARDER MES DONNÉES'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _restore,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger)),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('RESTAURER UNE SAUVEGARDE'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
