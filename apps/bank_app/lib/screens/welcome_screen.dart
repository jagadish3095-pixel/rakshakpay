import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'login_screen.dart';
import 'officer/officer_login_screen.dart';
import 'open_account_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool? _connected; // null = still checking

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _connected = null);
    try {
      await api.get('/');
      if (mounted) setState(() => _connected = true);
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(api: api, location: location)));
    _check();
  }

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
                    tooltip: 'Settings (server address)',
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: _openSettings,
                  ),
                ),
                if (_connected == false)
                  Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.wifi_off, color: Colors.deepOrange),
                      title: const Text('Not connected to the RakshakPay server'),
                      subtitle: Text('Tap here and enter the laptop address.\nNow: ${api.baseUrl}'),
                      onTap: _openSettings,
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
                TextButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerLoginScreen())),
                  icon: const Icon(Icons.badge, color: Colors.white70),
                  label: const Text('Bank staff login', style: TextStyle(color: Colors.white70)),
                ),
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
