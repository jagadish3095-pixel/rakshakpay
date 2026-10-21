import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'home_screen.dart';

/// Sign-up with KYC: mobile OTP, PAN, and a bank account that belongs to that PAN.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  final _pan = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _sentOtp;
  bool _verified = false;
  bool _busy = false;

  void _sendOtp() {
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile.text)) return showError(context, tr('Enter a valid mobile number'));
    setState(() => _sentOtp = (100000 + Random().nextInt(900000)).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.sms), const SizedBox(width: 8), Text(tr('SMS (demo)'))]),
        content: Text(tr('Your CoinVault code is {code}', {'code': _sentOtp})),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
      ),
    );
  }

  Future<void> _register() async {
    if (!_verified) return showError(context, tr('Verify your mobile number first'));
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/crypto/register', {
        'mobile': _mobile.text,
        'pan': _pan.text,
        'bank_account_no': _account.text,
        'ifsc': _ifsc.text,
        'pin': _pin.text,
      });
      await api.setToken(res['token']);
      await savedLogins.save(SavedLogin(_mobile.text, _pin.text, res['user']['name']));
      restartLive();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      showInfo(context, tr('KYC verified. Welcome, {name}!', {'name': res['user']['name']}));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Create CoinVault account'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
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
                  suffixIcon: _verified ? Icon(Icons.verified, color: strong(context, Colors.green)) : null,
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
                onPressed: () =>
                    _otp.text == _sentOtp ? setState(() => _verified = true) : showError(context, tr('Wrong OTP')),
                child: Text(tr('Verify')),
              ),
            ]),
          if (_verified) ...[
            const SizedBox(height: 8),
            const Text('KYC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
                tr('Indian law requires PAN for crypto exchanges. Your bank account must be in the same PAN; '
                    'your name is taken from it. Deposits are accepted only from this account.'),
                style: TextStyle(color: muted(context))),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pan,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseFormatter()],
              decoration: const InputDecoration(labelText: 'PAN', hintText: 'ABCDE1234F'),
              validator: (v) =>
                  RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(v ?? '') ? null : tr('Format: {example}', {'example': 'ABCDE1234F'}),
            ),
            TextFormField(
              controller: _account,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: tr('Bank account number')),
              validator: (v) => (v?.length ?? 0) >= 9 ? null : tr('Enter your account number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifsc,
              maxLength: 11,
              inputFormatters: [UpperCaseFormatter()],
              decoration: const InputDecoration(labelText: 'IFSC'),
              validator: (v) => (v?.length ?? 0) == 11 ? null : tr('11 characters'),
            ),
            TextFormField(
              controller: _pin,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: tr('Set 4-digit PIN (login & every trade)')),
              validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : tr('4 digits'),
            ),
            TextFormField(
              controller: _pin2,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: tr('Confirm PIN')),
              validator: (v) => v != _pin.text ? tr('PINs do not match') : null,
            ),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: _busy ? null : _register,
              child: Text(_busy ? tr('Verifying KYC…') : tr('Verify KYC & create account')),
            ),
          ],
        ]),
      ),
    );
  }
}
