import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'printer_settings_screen.dart';

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
  bool _autoBackupEnabled = false;
  String _autoBackupFrequency = 'daily';
  DateTime? _lastAutoBackupDate;

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
      _autoBackupEnabled = (settings['autoBackupEnabled'] ?? 'false') == 'true';
      _autoBackupFrequency = settings['autoBackupFrequency'] ?? 'daily';
      final lastAuto = settings['lastAutoBackupDate'];
      _lastAutoBackupDate =
          (lastAuto != null && lastAuto.isNotEmpty)
              ? DateTime.tryParse(lastAuto)
              : null;
      _loading = false;
    });
  }

  Future<void> _toggleAutoBackup(bool value) async {
    setState(() => _autoBackupEnabled = value);
    await _db.setSetting('autoBackupEnabled', value.toString());
    if (value) {
      final created = await _db.performAutoBackupIfDue();
      if (created && mounted) {
        _load();
      }
    }
  }

  Future<void> _setAutoBackupFrequency(String frequency) async {
    setState(() => _autoBackupFrequency = frequency);
    await _db.setSetting('autoBackupFrequency', frequency);
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
      final lang = context.read<LocaleProvider>().language;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(lang, 'settings_saved')),
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
    final lang = context.read<LocaleProvider>().language;
    try {
      final dbPath = await _db.getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception(tr(lang, 'settings_db_not_found'));
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
          SnackBar(
            content: Text(tr(lang, 'settings_backup_created')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(lang, 'settings_backup_error')} $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    final lang = context.read<LocaleProvider>().language;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(lang, 'settings_restore_title')),
        content: Text(tr(lang, 'settings_restore_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(lang, 'common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(lang, 'settings_restore_confirm'),
                style: const TextStyle(color: AppColors.danger)),
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
          SnackBar(
            content: Text(tr(lang, 'settings_restore_success')),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(lang, 'settings_restore_error')} $e'),
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
    final lang = context.watch<LocaleProvider>().language;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr(lang, 'settings_title'))),
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
                                ? tr(lang, 'settings_no_backup_yet')
                                : tr(lang, 'settings_backup_over_7days'),
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Consumer<LocaleProvider>(
                  builder: (context, locale, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(lang, 'settings_language_label'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        segments: const [
                          ButtonSegment(value: 'fr', label: Text('Français')),
                          ButtonSegment(value: 'ht', label: Text('Kreyòl ayisyen')),
                        ],
                        selected: {locale.language},
                        onSelectionChanged: (s) => locale.setLanguage(s.first),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Text(tr(lang, 'settings_store_info'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _storeNameController,
                  decoration: InputDecoration(labelText: tr(lang, 'settings_store_name')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storeAddressController,
                  decoration: InputDecoration(labelText: tr(lang, 'settings_store_address')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storePhoneController,
                  decoration: InputDecoration(labelText: tr(lang, 'settings_store_phone')),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                Text(tr(lang, 'settings_currency'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _exchangeRateController,
                  decoration: InputDecoration(
                    labelText: tr(lang, 'settings_exchange_rate'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                Text(tr(lang, 'settings_loyalty'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(lang, 'settings_loyalty_enabled')),
                  subtitle: Text(tr(lang, 'settings_loyalty_subtitle')),
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
                        : Text(tr(lang, 'settings_save')),
                  ),
                ),
                const SizedBox(height: 32),
                Text(tr(lang, 'settings_backup_data'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  _lastBackupDate != null
                      ? '${tr(lang, 'settings_last_backup')} ${DateFormat('dd/MM/yyyy à HH:mm').format(_lastBackupDate!)}'
                      : tr(lang, 'settings_no_backup'),
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
                    label: Text(tr(lang, 'settings_backup_button')),
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
                    label: Text(tr(lang, 'settings_restore_button')),
                  ),
                ),
                const SizedBox(height: 32),
                Text(tr(lang, 'settings_auto_backup'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  tr(lang, 'settings_auto_backup_desc'),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(lang, 'settings_auto_backup_enable')),
                  value: _autoBackupEnabled,
                  activeColor: AppColors.navy,
                  onChanged: _toggleAutoBackup,
                ),
                if (_autoBackupEnabled) ...[
                  const SizedBox(height: 4),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'daily', label: Text(tr(lang, 'settings_daily'))),
                      ButtonSegment(value: 'weekly', label: Text(tr(lang, 'settings_weekly'))),
                    ],
                    selected: {_autoBackupFrequency},
                    onSelectionChanged: (s) => _setAutoBackupFrequency(s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastAutoBackupDate != null
                        ? '${tr(lang, 'settings_last_auto_backup')} ${DateFormat('dd/MM/yyyy à HH:mm').format(_lastAutoBackupDate!)}'
                        : tr(lang, 'settings_no_auto_backup'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 32),
                Text(tr(lang, 'settings_printing'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  tr(lang, 'settings_printing_desc'),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrinterSettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: Text(tr(lang, 'settings_configure_printer')),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
