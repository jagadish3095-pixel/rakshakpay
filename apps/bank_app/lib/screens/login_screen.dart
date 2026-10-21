import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.prefillId});
  final String? prefillId;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _id = TextEditingController(text: widget.prefillId);
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  bool _remember = true;
  List<SavedLogin> _saved = [];

  @override
  void initState() {
    super.initState();
    _saved = savedLogins.all();
  }

  Future<void> _login(String loginId, String password, {bool remember = false}) async {
    if (loginId.isEmpty || password.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/auth/login',
          {'bank_code': brand.code, 'login_id': loginId, 'password': password});
      await api.setToken(res['token']);
      if (remember) {
        await savedLogins.save(SavedLogin(loginId, password, res['customer']['full_name']));
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forget(SavedLogin login) async {
    await savedLogins.remove(login.loginId);
    setState(() => _saved = savedLogins.all());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('{bank} Login', {'bank': brand.name}))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: BankLogo(brand, size: 80)),
          if (_saved.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(tr('Saved logins on this phone'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final s in _saved)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(s.name[0])),
                  title: Text(s.name),
                  subtitle: Text(s.loginId),
                  onTap: _busy ? null : () => _login(s.loginId, s.password),
                  trailing: IconButton(
                    tooltip: tr('Forget this login'),
                    icon: const Icon(Icons.close),
                    onPressed: () => _forget(s),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                const Expanded(child: Divider()),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(tr('or log in as someone else'))),
                const Expanded(child: Divider()),
              ]),
            ),
          ] else
            const SizedBox(height: 32),
          TextField(
            controller: _id,
            decoration: InputDecoration(
                labelText: tr('Customer ID or mobile number'), prefixIcon: const Icon(Icons.person)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: _hide,
            onSubmitted: (_) => _login(_id.text.trim(), _password.text, remember: _remember),
            decoration: InputDecoration(
              labelText: tr('Password'),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hide = !_hide)),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _remember,
            onChanged: (v) => setState(() => _remember = v!),
            title: Text(tr('Remember me on this phone')),
            subtitle: Text(tr('Demo only – saves the password for one-tap login')),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : () => _login(_id.text.trim(), _password.text, remember: _remember),
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(tr('Login'), style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
