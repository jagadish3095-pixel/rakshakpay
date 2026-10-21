import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'home_screen.dart';
import 'link_bank_screen.dart';

/// Sign up: verify mobile with OTP, enter name, set a 4-digit app passcode.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  final _name = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String? _sentOtp;
  bool _verified = false;
  bool _busy = false;

  void _sendOtp() {
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile.text)) {
      return showError(context, tr('Enter a valid 10-digit mobile number'));
    }
    // Demo only: real UPI apps verify the SIM by sending an SMS from the phone.
    setState(() => _sentOtp = (100000 + Random().nextInt(900000)).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.sms), const SizedBox(width: 8), Text(tr('SMS (demo)'))]),
        content: Text(tr('Your RakshakPay verification code is {otp}.', {'otp': _sentOtp})),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
      ),
    );
  }

  Future<void> _register() async {
    if (!_verified) return showError(context, tr('Verify your mobile number first'));
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/upi/register',
          {'mobile': _mobile.text, 'name': _name.text.trim(), 'passcode': _pass.text});
      await api.setToken(res['token']);
      await savedLogins.save(SavedLogin(_mobile.text, _pass.text, res['user']['name']));
      restartLive();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      // First thing a new user does: link a bank account.
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkBankScreen()));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Create your RakshakPay account'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr('Use the same mobile number that is registered with your bank. '
                'That is how UPI finds your bank accounts.')),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  controller: _mobile,
                  readOnly: _verified,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: tr('Mobile number'),
                    prefixText: '+91 ',
                    suffixIcon: _verified ? const Icon(Icons.verified, color: Colors.green) : null,
                  ),
                ),
              ),
              if (!_verified) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(onPressed: _sendOtp, child: Text(_sentOtp == null ? tr('Send OTP') : tr('Resend'))),
                ),
              ],
            ]),
            if (_sentOtp != null && !_verified)
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(labelText: tr('Enter OTP')),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => _otp.text == _sentOtp
                      ? setState(() => _verified = true)
                      : showError(context, tr('Wrong OTP')),
                  child: Text(tr('Verify')),
                ),
              ]),
            if (_verified) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: tr('Your full name')),
                validator: (v) => (v?.trim().length ?? 0) < 3 ? tr('Enter your name') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: tr('Set 4-digit app passcode (to open the app)')),
                validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : tr('Enter 4 digits'),
              ),
              TextFormField(
                controller: _pass2,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: tr('Confirm passcode')),
                validator: (v) => v != _pass.text ? tr('Passcodes do not match') : null,
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: _busy ? null : _register,
                child: Text(_busy ? tr('Creating…') : tr('Create account')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
