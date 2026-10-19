import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
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

  Future<void> _login() async {
    if (_id.text.isEmpty || _password.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/auth/login',
          {'bank_code': brand.code, 'login_id': _id.text.trim(), 'password': _password.text});
      await api.setToken(res['token']);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${brand.name} Login')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: BankLogo(brand, size: 80)),
          const SizedBox(height: 32),
          TextField(
            controller: _id,
            decoration: const InputDecoration(
                labelText: 'Customer ID or mobile number', prefixIcon: Icon(Icons.person)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: _hide,
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hide = !_hide)),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : _login,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Login', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
