import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'screens/lock_screen.dart';
import 'screens/welcome_screen.dart';
import 'services.dart';
import 'upi_link.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  await initUpiLinks(); // payment links from other apps, e.g. CoinVault deposits
  runApp(const UpiApp());
}

class UpiApp extends StatefulWidget {
  const UpiApp({super.key});

  @override
  State<UpiApp> createState() => _UpiAppState();
}

class _UpiAppState extends State<UpiApp> {
  late final AutoLock _autoLock;

  @override
  void initState() {
    super.initState();
    // Locks again after 30 seconds in the background.
    _autoLock = AutoLock(
      navigatorKey: navigatorKey,
      isLoggedIn: () => api.token != null,
      lockScreen: () => const LockScreen(onLaunch: false),
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
      title: 'RakshakPay',
      debugShowCheckedModeBanner: false,
      theme: rakshakTheme(),
      // Logged in before? Ask for the passcode before showing anything.
      home: api.token == null ? const WelcomeScreen() : const LockScreen(onLaunch: true),
    );
  }
}
