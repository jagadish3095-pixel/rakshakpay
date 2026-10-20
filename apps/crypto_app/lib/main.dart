import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'brand.dart';
import 'screens/lock_screen.dart';
import 'screens/welcome_screen.dart';
import 'services.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  runApp(const CryptoApp());
}

class CryptoApp extends StatefulWidget {
  const CryptoApp({super.key});

  @override
  State<CryptoApp> createState() => _CryptoAppState();
}

class _CryptoAppState extends State<CryptoApp> {
  late final AutoLock _autoLock;

  @override
  void initState() {
    super.initState();
    // 2 minutes, so paying in RakshakPay and coming back does not lock every time.
    _autoLock = AutoLock(
      navigatorKey: navigatorKey,
      isLoggedIn: () => api.token != null,
      lockScreen: () => const LockScreen(onLaunch: false),
      lockAfter: const Duration(minutes: 2),
    );
  }

  @override
  void dispose() {
    _autoLock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CoinVault',
      debugShowCheckedModeBanner: false,
      theme: coinVaultTheme(),
      home: api.token == null ? const WelcomeScreen() : const LockScreen(onLaunch: true),
    );
  }
}
