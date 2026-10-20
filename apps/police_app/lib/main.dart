import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  runApp(const PoliceApp());
}

class PoliceApp extends StatelessWidget {
  const PoliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RakshakPay Cyber Police',
      debugShowCheckedModeBanner: false,
      theme: policeTheme(),
      home: api.token == null ? const LoginScreen() : const Shell(),
    );
  }
}
