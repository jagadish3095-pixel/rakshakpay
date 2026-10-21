import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'l10n.dart';
import 'screens/lock_screen.dart';
import 'screens/welcome_screen.dart';
import 'services.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  await appSettings.init();
  addTranslations(appTranslations);
  await officerApi.init();
  runApp(const BankApp());
}

class BankApp extends StatefulWidget {
  const BankApp({super.key});

  @override
  State<BankApp> createState() => _BankAppState();
}

class _BankAppState extends State<BankApp> {
  late final AutoLock _autoLock;

  @override
  void initState() {
    super.initState();
    // Locks again after 30 seconds in the background, like real banking apps.
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
    // Rebuilds when night mode or the language is changed in Settings.
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        title: brand.name,
        debugShowCheckedModeBanner: false,
        theme: brandTheme(brand.color, Brightness.light),
        darkTheme: brandTheme(brand.color, Brightness.dark),
        themeMode: appSettings.themeMode,
        locale: appSettings.locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        // Logged in before? Ask for the MPIN before showing anything.
        home: api.token == null ? const WelcomeScreen() : const LockScreen(onLaunch: true),
      ),
    );
  }
}
