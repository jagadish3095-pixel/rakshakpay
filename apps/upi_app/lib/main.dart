import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  runApp(const UpiApp());
}

class UpiApp extends StatelessWidget {
  const UpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RakshakPay',
      debugShowCheckedModeBanner: false,
      theme: rakshakTheme(),
      home: api.token == null ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}
