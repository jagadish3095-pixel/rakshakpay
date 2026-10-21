import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../../services.dart';

/// Mule verification at the branch: re-KYC, the customer's statement and the
/// officer's recommendation. The police make the final decision.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.customer, required this.account});
  final Map<String, dynamic> customer;
  final Map<String, dynamic> account;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int _step = 0;
  bool _busy = false;
  List<String> _reasons = [];

  // Step 1: re-KYC
  bool _pan = false, _aadhaar = false, _photo = false, _otpOk = false;
  String? _otp;
  final _otpField = TextEditingController();

  // Step 2: statement
  String? _reason;
  final _statement = TextEditingController();

  // Step 3: recommendation
  String? _recommendation;
  bool _undertaking = false, _awareness = false;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    officerApi.get('/api/officer/me').then((me) {
      if (mounted) setState(() => _reasons = (me['reasons'] as List).cast<String>());
    }, onError: (e) {
      if (mounted) showError(context, e);
    });
  }

  void _sendOtp() {
    setState(() => _otp = (100000 + Random().nextInt(900000)).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.sms), const SizedBox(width: 8), Text(tr('SMS to customer (demo)'))]),
        content: Text(tr('Sent to {mobile}:\n"{bank} branch verification code: {otp}"',
            {'mobile': '+91 ${widget.customer['mobile']}', 'bank': brand.name, 'otp': _otp})),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
      ),
    );
  }

  void _next() {
    switch (_step) {
      case 0 when !(_pan && _aadhaar && _photo && _otpOk):
        return showError(context, tr('Complete all four re-KYC checks'));
      case 1 when _reason == null || _statement.text.trim().length < 10:
        return showError(context, tr('Choose what happened and write the customer\'s statement'));
      case 2:
        _submit();
        return;
    }
    setState(() => _step++);
  }

  Future<void> _submit() async {
    if (_recommendation == null) return showError(context, tr('Choose your recommendation'));
    if (_recommendation == 'TRICKED' && !(_undertaking && _awareness)) {
      return showError(context, tr('For "tricked", the undertaking and awareness session are required'));
    }
    setState(() => _busy = true);
    try {
      await officerApi.post('/api/officer/verifications', {
        'account_no': widget.account['account_no'],
        'kyc_checks': ['pan_original', 'aadhaar_original', 'live_photo', 'mobile_otp'],
        'reason_category': _reason,
        'statement': _statement.text,
        'recommendation': _recommendation,
        'officer_notes': _notes.text,
        'undertaking_signed': _undertaking,
        'awareness_done': _awareness,
      });
      if (!mounted) return;
      showInfo(context, tr('Sent to the cyber police for a decision'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Verify {name}', {'name': c['name']}))),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _busy ? null : _next,
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, d) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            FilledButton(onPressed: d.onStepContinue, child: Text(_step == 2 ? tr('Send to police') : tr('Next'))),
            if (_step > 0) TextButton(onPressed: d.onStepCancel, child: Text(tr('Back'))),
          ]),
        ),
        steps: [
          Step(
            title: Text(tr('Re-KYC with original documents')),
            isActive: _step >= 0,
            content: Column(children: [
              CheckboxListTile(
                value: _pan,
                onChanged: (v) => setState(() => _pan = v!),
                title: Text(tr('Original PAN card seen: {pan}', {'pan': c['pan']})),
              ),
              CheckboxListTile(
                value: _aadhaar,
                onChanged: (v) => setState(() => _aadhaar = v!),
                title: Text(tr('Original Aadhaar seen: {aadhaar}', {'aadhaar': c['aadhaar_masked']})),
              ),
              CheckboxListTile(
                value: _photo,
                onChanged: (v) => setState(() => _photo = v!),
                title: Text(tr('Live photo taken at the branch and matches the KYC photo')),
              ),
              ListTile(
                title: Text(_otpOk ? tr('Mobile verified ✔') : tr('Mobile {mobile}', {'mobile': '+91 ${c['mobile']}'})),
                trailing: _otpOk ? const Icon(Icons.verified, color: Colors.green)
                    : OutlinedButton(onPressed: _sendOtp, child: Text(tr('Send OTP'))),
              ),
              if (_otp != null && !_otpOk)
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _otpField, decoration: InputDecoration(labelText: tr('OTP from customer')))),
                  TextButton(
                    onPressed: () =>
                        _otpField.text == _otp ? setState(() => _otpOk = true) : showError(context, tr('Wrong OTP')),
                    child: Text(tr('Verify')),
                  ),
                ]),
            ]),
          ),
          Step(
            title: Text(tr("Customer's statement")),
            isActive: _step >= 1,
            content: Column(children: [
              DropdownButtonFormField<String>(
                initialValue: _reason,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr('What does the customer say happened?')),
                items: [for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r))],
                onChanged: (v) => setState(() => _reason = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _statement,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: tr('Statement in the customer\'s words'),
                  hintText: tr('How did money from the fraud reach your account? Who used it?'),
                ),
              ),
            ]),
          ),
          Step(
            title: Text(tr('Officer recommendation')),
            isActive: _step >= 2,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RadioGroup<String>(
                groupValue: _recommendation,
                onChanged: (v) => setState(() => _recommendation = v),
                child: Column(children: [
                  RadioListTile(value: 'INNOCENT', title: Text(tr('Innocent')),
                      subtitle: Text(tr('Account hacked or identity misused without their knowledge'))),
                  RadioListTile(value: 'TRICKED', title: Text(tr('Tricked')),
                      subtitle: Text(tr('Fooled by a job / commission offer; did not know it was fraud'))),
                  RadioListTile(value: 'INVOLVED', title: Text(tr('Knowingly involved')),
                      subtitle: Text(tr('Rented or sold the account, or acted for the fraudsters'))),
                ]),
              ),
              if (_recommendation == 'TRICKED') ...[
                CheckboxListTile(
                  value: _undertaking,
                  onChanged: (v) => setState(() => _undertaking = v!),
                  title: Text(tr('Customer signed an undertaking not to share their account, card, SIM or OTP '
                      'and to repay any amount the court orders')),
                ),
                CheckboxListTile(
                  value: _awareness,
                  onChanged: (v) => setState(() => _awareness = v!),
                  title: Text(tr('Customer attended the cyber-fraud awareness session')),
                ),
              ],
              TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: tr('Notes for the police (optional)'))),
              const SizedBox(height: 8),
              Text(tr('The police make the final decision. Money held for victims stays on hold in every case.'),
                  style: TextStyle(color: muted(context))),
            ]),
          ),
        ],
      ),
    );
  }
}
