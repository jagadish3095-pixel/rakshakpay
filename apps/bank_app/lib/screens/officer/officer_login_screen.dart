import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../../services.dart';
import 'officer_home_screen.dart';

/// Login for branch staff (not customers).
class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  late final _staffId = TextEditingController(text: '${brand.code}001');
  final _password = TextEditingController();
  bool _busy = false;
  List<SavedLogin> _saved = [];

  @override
  void initState() {
    super.initState();
    _saved = officerLogins.all();
  }

  Future<void> _login(String staffId, String password) async {
    if (staffId.isEmpty || password.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await officerApi.post(
          '/api/officer/login', {'bank_code': brand.code, 'staff_id': staffId, 'password': password});
      await officerApi.setToken(res['token']);
      await officerLogins.save(SavedLogin(staffId.toUpperCase(), password, res['officer']['name']));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OfficerHomeScreen()));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('{bank} staff login', {'bank': brand.name}))),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Icon(Icons.badge, size: 72, color: isDark(context) ? Color.lerp(brand.color, Colors.white, 0.4) : brand.color),
        const SizedBox(height: 8),
        Text(tr('Branch desk'), textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(tr('For bank staff only: customer verification and mule-list delisting.'),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        for (final s in _saved)
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: Text(s.name),
              subtitle: Text(s.loginId),
              onTap: _busy ? null : () => _login(s.loginId, s.password),
            ),
          ),
        TextField(controller: _staffId, decoration: InputDecoration(labelText: tr('Staff ID'))),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(labelText: tr('Password')),
          onSubmitted: (_) => _login(_staffId.text.trim(), _password.text),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: _busy ? null : () => _login(_staffId.text.trim(), _password.text),
          child: Text(_busy ? tr('Signing in…') : tr('Sign in')),
        ),
        const SizedBox(height: 8),
        Text(tr('Demo staff ID {id}, password {password}', {'id': '${brand.code}001', 'password': 'officer123'}),
            textAlign: TextAlign.center, style: TextStyle(color: muted(context), fontSize: 12)),
      ]),
    );
  }
}
