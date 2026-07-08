import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        aspectRatio: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: const Color(0xFFF1ECE3),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              splashColor: AppColors.clay.withOpacity(0.18),
              child: Center(
                child: icon ??
                    Text(label,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy)),
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
        child: Stack(
          children: [
            // Motif géométrique discret, inspiré des textiles haïtiens,
            // qui casse la platitude d'un simple fond marine uni.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: IgnorePointer(
                child: CustomPaint(painter: _TriangleWeavePainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  const FafouttLogo(size: 68),
                  const SizedBox(height: 18),
                  Text('Fafoutt Store',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 25,
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: filled ? 12 : 14,
                        height: filled ? 12 : 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? AppColors.gold : Colors.transparent,
                          border: filled
                              ? null
                              : Border.all(color: Colors.white38, width: 1.4),
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
                                    color: Color(0xFFE8A292), fontSize: 13))
                            : null,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBF8F3),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.sheet)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDD3C4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
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
                              icon: Icon(Icons.backspace_outlined,
                                  size: 20, color: AppColors.clay),
                              onTap: _removeDigit),
                        ]),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Motif discret de triangles entrelacés (clin d'œil aux textiles et
/// motifs graphiques haïtiens), dessiné en léger surimpression sur le
/// marine de l'écran de connexion.
class _TriangleWeavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGold = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final paintWhite = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.fill;

    const step = 46.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final up = ((x / step).round() + (y / step).round()) % 2 == 0;
        final path = Path();
        if (up) {
          path.moveTo(x, y + step);
          path.lineTo(x + step / 2, y);
          path.lineTo(x + step, y + step);
        } else {
          path.moveTo(x, y);
          path.lineTo(x + step, y);
          path.lineTo(x + step / 2, y + step);
        }
        path.close();
        canvas.drawPath(path, up ? paintGold : paintWhite);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
