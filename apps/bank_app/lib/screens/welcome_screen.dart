import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
import '../services.dart';
import 'login_screen.dart';
import 'open_account_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [brand.color, Color.lerp(brand.color, Colors.black, 0.35)!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SettingsScreen(api: api, location: location))),
                  ),
                ),
                const Spacer(),
                Center(child: BankLogo(brand, size: 110)),
                const SizedBox(height: 20),
                Text(brand.name, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(brand.tagline, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const Spacer(flex: 2),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: brand.color,
                      padding: const EdgeInsets.all(16)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Login', style: TextStyle(fontSize: 17)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.all(16)),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenAccountScreen())),
                  child: const Text('Open a new account', style: TextStyle(fontSize: 17)),
                ),
                const SizedBox(height: 16),
                const Text('Demo bank for RakshakPay • Fake money only',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
