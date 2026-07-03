import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  bool _checking = false;
  String? _error;

  Future<void> _tryLogin() async {
    if (_pin.length != 4) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final success = await context.read<SessionProvider>().login(_pin);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _error = 'Code PIN incorrect';
        _pin = '';
        _checking = false;
      });
    }
    // Si succès, le widget parent (main.dart) bascule automatiquement
    // vers l'application principale grâce au Consumer<SessionProvider>.
  }

  void _addDigit(String digit) {
    if (_pin.length >= 4 || _checking) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) _tryLogin();
  }

  void _removeDigit() {
    if (_pin.isEmpty || _checking) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _buildKey(String label, {VoidCallback? onTap, Widget? icon}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Center(
                child: icon ??
                    Text(label,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              const FafouttLogo(size: 64),
              const SizedBox(height: 16),
              const Text('Fafoutt Store',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Entrez votre code PIN pour continuer',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Première utilisation ? PIN par défaut : 0000',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.gold : Colors.white24,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : _error != null
                        ? Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13))
                        : null,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      _buildKey('1', onTap: () => _addDigit('1')),
                      _buildKey('2', onTap: () => _addDigit('2')),
                      _buildKey('3', onTap: () => _addDigit('3')),
                    ]),
                    Row(children: [
                      _buildKey('4', onTap: () => _addDigit('4')),
                      _buildKey('5', onTap: () => _addDigit('5')),
                      _buildKey('6', onTap: () => _addDigit('6')),
                    ]),
                    Row(children: [
                      _buildKey('7', onTap: () => _addDigit('7')),
                      _buildKey('8', onTap: () => _addDigit('8')),
                      _buildKey('9', onTap: () => _addDigit('9')),
                    ]),
                    Row(children: [
                      const Spacer(),
                      _buildKey('0', onTap: () => _addDigit('0')),
                      _buildKey('',
                          icon: const Icon(Icons.backspace_outlined,
                              size: 20, color: AppColors.textSecondary),
                          onTap: _removeDigit),
                    ]),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
