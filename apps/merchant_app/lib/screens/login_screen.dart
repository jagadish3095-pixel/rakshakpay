import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'soundbox_screen.dart';

/// Shop owners log in with the mobile number and passcode they use in RakshakPay.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  List<SavedLogin> _saved = [];

  @override
  void initState() {
    super.initState();
    _saved = savedLogins.all();
  }

  Future<void> _login(String mobile, String passcode) async {
    if (mobile.isEmpty || passcode.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/upi/login', {'mobile': mobile, 'passcode': passcode});
      await api.setToken(res['token']);
      await savedLogins.save(SavedLogin(mobile, passcode, res['user']['name']));
      restartLive();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SoundboxScreen()), (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RakshakPay Business'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SettingsScreen(api: api, location: location))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: RakshakLogo(size: 90)),
          const SizedBox(height: 12),
          const Text('Payment soundbox for your shop', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Log in with your RakshakPay mobile number and passcode. '
              'Your shop must have a Current (Merchant) account linked in RakshakPay.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          if (_saved.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (final s in _saved)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: kSaffron, child: Icon(Icons.storefront, color: Colors.white)),
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
            const Divider(height: 32),
          ] else
            const SizedBox(height: 24),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 '),
          ),
          TextField(
            controller: _pass,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'RakshakPay passcode'),
            onSubmitted: (_) => _login(_mobile.text, _pass.text),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : () => _login(_mobile.text, _pass.text),
            child: Text(_busy ? 'Logging in…' : 'Log in'),
          ),
        ],
      ),
    );
  }
}
