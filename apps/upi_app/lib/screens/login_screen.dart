import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _pass = TextEditingController();
  bool _remember = true;
  bool _busy = false;
  List<SavedLogin> _saved = [];

  @override
  void initState() {
    super.initState();
    _saved = savedLogins.all();
  }

  Future<void> _login(String mobile, String passcode, {bool remember = false}) async {
    if (mobile.isEmpty || passcode.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/upi/login', {'mobile': mobile, 'passcode': passcode});
      await api.setToken(res['token']);
      if (remember) await savedLogins.save(SavedLogin(mobile, passcode, res['user']['name']));
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
      appBar: AppBar(title: Text(tr('Log in to RakshakPay'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: RakshakLogo(size: 80)),
          if (_saved.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(tr('Saved on this phone'), style: Theme.of(context).textTheme.titleSmall),
            for (final s in _saved)
              Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: kSaffron, child: Text(s.name[0])),
                  title: Text(s.name),
                  subtitle: Text('+91 ${s.loginId}'),
                  onTap: _busy ? null : () => _login(s.loginId, s.password),
                  trailing: IconButton(
                    tooltip: tr('Forget'),
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
            const SizedBox(height: 32),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('Mobile number'), prefixText: '+91 '),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pass,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('4-digit passcode')),
            onSubmitted: (_) => _login(_mobile.text, _pass.text, remember: _remember),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _remember,
            onChanged: (v) => setState(() => _remember = v!),
            title: Text(tr('Remember me on this phone')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : () => _login(_mobile.text, _pass.text, remember: _remember),
            child: Text(_busy ? tr('Logging in…') : tr('Log in')),
          ),
        ],
      ),
    );
  }
}
