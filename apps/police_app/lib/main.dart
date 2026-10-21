import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'l10n.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  await appSettings.init();
  addTranslations(appTranslations);
  runApp(const PoliceApp());
}

class PoliceApp extends StatelessWidget {
  const PoliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds when night mode or the language is changed in Settings.
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => MaterialApp(
        title: 'RakshakPay Cyber Police',
        debugShowCheckedModeBanner: false,
        theme: policeTheme(),
        darkTheme: policeTheme(Brightness.dark),
        themeMode: appSettings.themeMode,
        locale: appSettings.locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: api.token == null ? const LoginScreen() : const Shell(),
      ),
    );
  }
}
