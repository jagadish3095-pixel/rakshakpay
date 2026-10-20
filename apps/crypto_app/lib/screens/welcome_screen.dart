import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
import '../services.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Start screen with saved logins and a login form.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _mobile = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  bool? _connected;
  List<SavedLogin> _saved = [];

  @override
  void initState() {
    super.initState();
    _saved = savedLogins.all();
    _check();
  }

  Future<void> _check() async {
    try {
      await api.get('/');
      if (mounted) setState(() => _connected = true);
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  Future<void> _login(String mobile, String pin) async {
    if (mobile.isEmpty || pin.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/crypto/login', {'mobile': mobile, 'pin': pin});
      await api.setToken(res['token']);
      await savedLogins.save(SavedLogin(mobile, pin, res['user']['name']));
      restartLive();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(api: api, location: location)));
            _check();
          },
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Center(child: CoinVaultLogo(size: 96)),
        const SizedBox(height: 12),
        const Text('CoinVault', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kGold)),
        const Text('Buy, sell and store crypto in India', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70)),
        const Text('Demo exchange • Fake coins and fake money', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12)),
        if (_connected == false)
          Card(
            color: Colors.orange.shade900,
            margin: const EdgeInsets.only(top: 16),
            child: const ListTile(
              leading: Icon(Icons.wifi_off),
              title: Text('Not connected to the server'),
              subtitle: Text('Check internet, or the address in Settings (top right).'),
            ),
          ),
        const SizedBox(height: 24),
        for (final s in _saved)
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: kTeal, child: Icon(Icons.person, color: Colors.white)),
              title: Text(s.name),
              subtitle: Text('+91 ${s.loginId}'),
              onTap: _busy ? null : () => _login(s.loginId, s.password),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await savedLogins.remove(s.loginId);
                  setState(() => _saved = savedLogins.all());
                },
              ),
            ),
          ),
        if (_saved.isNotEmpty) const SizedBox(height: 16),
        TextField(
          controller: _mobile,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 '),
        ),
        TextField(
          controller: _pin,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: '4-digit PIN'),
          onSubmitted: (_) => _login(_mobile.text, _pin.text),
        ),
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: _busy ? null : () => _login(_mobile.text, _pin.text),
          child: Text(_busy ? 'Logging in…' : 'Log in'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), foregroundColor: kGold),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Create account (KYC)'),
        ),
      ]),
    );
  }
}
