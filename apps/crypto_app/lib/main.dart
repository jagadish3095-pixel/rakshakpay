import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'brand.dart';
import 'l10n.dart';
import 'screens/lock_screen.dart';
import 'screens/welcome_screen.dart';
import 'services.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  await appSettings.init(defaultTheme: ThemeMode.dark);
  addTranslations(appTranslations);
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
    // Rebuilds when night mode or the language is changed in Settings.
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'CoinVault',
        debugShowCheckedModeBanner: false,
        theme: coinVaultTheme(Brightness.light),
        darkTheme: coinVaultTheme(Brightness.dark),
        themeMode: appSettings.themeMode,
        locale: appSettings.locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: api.token == null ? const WelcomeScreen() : const LockScreen(onLaunch: true),
      ),
    );
  }
}
