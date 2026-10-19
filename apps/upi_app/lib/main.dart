import 'package:flutter/material.dart';

import 'screens/lock_screen.dart';
import 'screens/welcome_screen.dart';
import 'services.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  runApp(const UpiApp());
}

class UpiApp extends StatefulWidget {
  const UpiApp({super.key});

  @override
  State<UpiApp> createState() => _UpiAppState();
}

class _UpiAppState extends State<UpiApp> with WidgetsBindingObserver {
  /// Lock again if the app was in the background longer than this.
  static const _lockAfter = Duration(seconds: 30);
  DateTime? _backgroundSince;
  bool _lockShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundSince = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundSince;
      _backgroundSince = null;
      if (since != null && api.token != null && !_lockShown && DateTime.now().difference(since) > _lockAfter) {
        _showLock();
      }
    }
  }

  Future<void> _showLock() async {
    _lockShown = true;
    await navigatorKey.currentState?.push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const LockScreen(onLaunch: false),
    ));
    _lockShown = false;
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
