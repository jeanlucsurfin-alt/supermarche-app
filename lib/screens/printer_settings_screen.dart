import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import '../services/bluetooth_printer_service.dart';
import '../theme/app_theme.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  List<BluetoothDevice> _devices = [];
  String? _savedAddress;
  String? _savedName;
  bool _loading = true;
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await _printerService.getPairedDevices();
      final savedName = await _printerService.getSavedPrinterName();
      setState(() {
        _devices = devices;
        _savedName = savedName;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error =
            'Impossible d\'accéder au Bluetooth. Vérifiez qu\'il est activé et que la permission est accordée.';
      });
    }
  }

  Future<void> _selectDevice(BluetoothDevice device) async {
    setState(() => _connecting = true);
    final connected = await _printerService.connect(device);
    if (connected) {
      await _printerService.savePrinter(device);
      setState(() {
        _savedAddress = device.address;
        _savedName = device.name;
        _connecting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecté à ${device.name ?? 'l\'imprimante'}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      setState(() => _connecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la connexion à l\'imprimante'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imprimante Bluetooth')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_savedName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.print_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Imprimante enregistrée : $_savedName',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            Text(
              'Associez d\'abord votre imprimante depuis les paramètres Bluetooth de votre téléphone, puis sélectionnez-la ci-dessous.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth_disabled_rounded,
                        size: 40, color: AppColors.danger),
                    const SizedBox(height: 8),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                ),
              )
            else if (_devices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text('Aucun appareil Bluetooth associé trouvé',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ..._devices.map((device) {
                final isSelected = device.address == _savedAddress ||
                    (_savedAddress == null && device.name == _savedName);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: _connecting ? null : () => _selectDevice(device),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.navy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.print_outlined,
                          color: AppColors.navy, size: 18),
                    ),
                    title: Text(device.name ?? 'Appareil sans nom',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(device.address ?? '',
                        style: const TextStyle(fontSize: 11)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.success)
                        : const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
