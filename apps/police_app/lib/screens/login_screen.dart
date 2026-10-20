import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _badge = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  List<SavedLogin> _saved = [];

  @override
  void initState() {
    super.initState();
    _saved = savedLogins.all();
  }

  Future<void> _login(String badge, String password) async {
    if (badge.isEmpty || password.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/police/login', {'badge_id': badge, 'password': password});
      await api.setToken(res['token']);
      await savedLogins.save(SavedLogin(badge.toUpperCase(), password, res['officer']['name']));
      live.stop();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell()));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.local_police, size: 72, color: kNavy),
                  const SizedBox(height: 8),
                  const Text('Cyber Police', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kNavy)),
                  const Text('RakshakPay fraud response console', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  for (final s in _saved)
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: kNavy, child: Icon(Icons.badge, color: Colors.white)),
                      title: Text(s.name),
                      subtitle: Text(s.loginId),
                      onTap: _busy ? null : () => _login(s.loginId, s.password),
                    ),
                  TextField(controller: _badge, decoration: const InputDecoration(labelText: 'Badge ID')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _login(_badge.text.trim(), _password.text),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                    onPressed: _busy ? null : () => _login(_badge.text.trim(), _password.text),
                    child: Text(_busy ? 'Signing in…' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => SettingsScreen(api: api, location: location))),
                    child: const Text('Server settings'),
                  ),
                  const Text('Demo officer: CYB001 / police123', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black45)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
