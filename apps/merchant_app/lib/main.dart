import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'l10n.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'services.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  await appSettings.init();
  addTranslations(appTranslations);
  await announcer.init();
  runApp(const MerchantApp());
}

class MerchantApp extends StatefulWidget {
  const MerchantApp({super.key});

  @override
  State<MerchantApp> createState() => _MerchantAppState();
}

class _MerchantAppState extends State<MerchantApp> {
  late final AutoLock _autoLock;

  @override
  void initState() {
    super.initState();
    // A shop phone is often left on the counter, so lock after 2 minutes away.
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
    // Rebuilds when night mode or the language is changed in Settings.
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'RakshakPay Business',
        debugShowCheckedModeBanner: false,
        theme: rakshakTheme(),
        darkTheme: rakshakTheme(Brightness.dark),
        themeMode: appSettings.themeMode,
        locale: appSettings.locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: api.token == null ? const LoginScreen() : const LockScreen(onLaunch: true),
      ),
    );
  }
}
