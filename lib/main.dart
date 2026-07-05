import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/category_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FafouttStoreApp());
}

class FafouttStoreApp extends StatelessWidget {
  const FafouttStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Fafoutt Store',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Affiche l'écran de connexion tant qu'aucun employé n'est authentifié,
/// puis bascule sur l'application principale.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return session.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
