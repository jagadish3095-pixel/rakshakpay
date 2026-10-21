import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'login_screen.dart';

/// New account opening with KYC, in 5 steps.
class OpenAccountScreen extends StatefulWidget {
  const OpenAccountScreen({super.key});

  @override
  State<OpenAccountScreen> createState() => _OpenAccountScreenState();
}

class _OpenAccountScreenState extends State<OpenAccountScreen> {
  final _forms = List.generate(5, (_) => GlobalKey<FormState>());
  int _step = 0;
  bool _busy = false;

  // Step 1 – personal
  final _name = TextEditingController();
  DateTime? _dob;
  String _gender = 'Female';
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  String? _sentOtp;
  bool _mobileVerified = false;

  // Step 2 – KYC
  final _pan = TextEditingController();
  final _aadhaar = TextEditingController();
  bool _consent = false;

  // Step 3 – address
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  List<City> _cities = [];
  City? _city;

  // Step 4 – account
  String _type = 'SAVINGS';
  final _business = TextEditingController();
  List<Branch> _branches = [];
  Branch? _branch;
  final _deposit = TextEditingController(text: '10000');

  // Step 5 – security
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _mpin = TextEditingController();
  final _cardPin = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Cities and branches come from the server. Called again if the first try failed.
  Future<void> _load() async {
    try {
      final bank = await api.get('/api/banks/${brand.code}');
      final cities = await location.cities();
      if (!mounted) return;
      setState(() {
        _branches = [for (final b in bank['branches']) Branch.fromJson(b)];
        _cities = cities;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  bool get _loaded => _cities.isNotEmpty && _branches.isNotEmpty;

  /// Shown instead of an empty dropdown when the server could not be reached.
  Widget _notLoaded(String message) => Card(
        color: softBg(context, Colors.orange),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message),
            const SizedBox(height: 4),
            Text(tr('Server: {url}', {'url': api.baseUrl}), style: const TextStyle(fontSize: 12)),
            Row(children: [
              TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(tr('Retry'))),
              TextButton.icon(
                icon: const Icon(Icons.settings),
                label: Text(tr('Settings')),
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SettingsScreen(api: api, location: location)));
                  _load();
                },
              ),
            ]),
          ]),
        ),
      );

  // ---------- validators ----------
  String? _pinValidator(String? v) => RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : tr('Enter 4 digits');

  void _sendOtp() {
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile.text)) {
      showError(context, tr('Enter a valid 10-digit mobile number first'));
      return;
    }
    // Demo only: a real bank sends this by SMS.
    setState(() {
      _sentOtp = (100000 + Random().nextInt(900000)).toString();
      _mobileVerified = false;
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.sms), const SizedBox(width: 8), Text(tr('SMS (demo)'))]),
        content: Text(tr('Your {bank} OTP is {otp}. Do not share it with anyone.',
            {'bank': brand.name, 'otp': _sentOtp})),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
      ),
    );
  }

  void _verifyOtp() {
    if (_otp.text == _sentOtp) {
      setState(() => _mobileVerified = true);
    } else {
      showError(context, tr('Wrong OTP'));
    }
  }

  void _next() {
    if (!_forms[_step].currentState!.validate()) return;
    if (_step == 0 && _dob == null) return showError(context, tr('Select your date of birth'));
    if (_step == 0 && !_mobileVerified) return showError(context, tr('Verify your mobile number with OTP'));
    if (_step == 1 && !_consent) return showError(context, tr('Please give Aadhaar e-KYC consent'));
    if (_step < 4) {
      if (!_loaded) _load();
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/banks/${brand.code}/open-account', {
        'full_name': _name.text,
        'dob': _dob!.toIso8601String().substring(0, 10),
        'gender': _gender,
        'mobile': _mobile.text,
        'email': _email.text,
        'pan': _pan.text,
        'aadhaar': _aadhaar.text,
        'address': _address.text,
        'city': _city!.name,
        'state': _city!.state,
        'pincode': _pincode.text,
        'account_type': _type,
        'business_name': _business.text,
        'branch_id': _branch!.id,
        'password': _password.text,
        'mpin': _mpin.text,
        'card_pin': _cardPin.text,
        'initial_deposit': parsePaise(_deposit.text) ?? 0,
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _AccountCreatedScreen(res)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Open new account'))),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _busy ? null : _next,
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(children: [
            FilledButton(
              onPressed: details.onStepContinue,
              child: Text(_step == 4 ? (_busy ? tr('Opening…') : tr('Open account')) : tr('Next')),
            ),
            const SizedBox(width: 12),
            if (_step > 0) TextButton(onPressed: details.onStepCancel, child: Text(tr('Back'))),
          ]),
        ),
        steps: [
          Step(title: Text(tr('Personal details')), isActive: _step >= 0, content: _personal()),
          Step(title: Text(tr('KYC documents')), isActive: _step >= 1, content: _kyc()),
          Step(title: Text(tr('Address')), isActive: _step >= 2, content: _addressStep()),
          Step(title: Text(tr('Account & branch')), isActive: _step >= 3, content: _accountStep()),
          Step(title: Text(tr('Security')), isActive: _step >= 4, content: _security()),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 12);

  Widget _personal() => Form(
        key: _forms[0],
        child: Column(children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: tr('Full name (as per PAN)')),
            validator: (v) => RegExp(r'^[A-Za-z .]{3,}$').hasMatch(v?.trim() ?? '') ? null : tr('Letters only'),
          ),
          _gap(),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(now.year - 25),
                firstDate: DateTime(1930),
                lastDate: DateTime(now.year - 18, now.month, now.day),
              );
              if (picked != null) setState(() => _dob = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(labelText: tr('Date of birth'), suffixIcon: const Icon(Icons.calendar_month)),
              child: Text(_dob == null ? tr('Select') : formatDate(_dob!.toIso8601String())),
            ),
          ),
          _gap(),
          DropdownButtonFormField(
            initialValue: _gender,
            decoration: InputDecoration(labelText: tr('Gender')),
            items: [
              DropdownMenuItem(value: 'Female', child: Text(tr('Female'))),
              DropdownMenuItem(value: 'Male', child: Text(tr('Male'))),
              DropdownMenuItem(value: 'Other', child: Text(tr('Other'))),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          _gap(),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                readOnly: _mobileVerified,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: tr('Mobile number'),
                  prefixText: '+91 ',
                  suffixIcon: _mobileVerified ? const Icon(Icons.verified, color: Colors.green) : null,
                ),
                validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v ?? '') ? null : tr('Invalid mobile'),
              ),
            ),
            const SizedBox(width: 8),
            if (!_mobileVerified)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(onPressed: _sendOtp, child: Text(_sentOtp == null ? tr('Send OTP') : tr('Resend'))),
              ),
          ]),
          if (_sentOtp != null && !_mobileVerified)
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
              FilledButton.tonal(onPressed: _verifyOtp, child: Text(tr('Verify'))),
            ]),
          _gap(),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: tr('Email (optional)')),
          ),
        ]),
      );

  Widget _kyc() => Form(
        key: _forms[1],
        child: Column(children: [
          TextFormField(
            controller: _pan,
            maxLength: 10,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseFormatter()],
            decoration: InputDecoration(labelText: tr('PAN number'), hintText: 'ABCDE1234F'),
            validator: (v) => RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(v ?? '') ? null : tr('Format: ABCDE1234F'),
          ),
          _gap(),
          TextFormField(
            controller: _aadhaar,
            maxLength: 12,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('Aadhaar number')),
            validator: (v) => RegExp(r'^[2-9]\d{11}$').hasMatch(v ?? '') ? null : tr('12 digits, not starting 0/1'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v!),
            title: Text(tr('I consent to Aadhaar-based e-KYC verification for opening this account.')),
          ),
        ]),
      );

  Widget _addressStep() => Form(
        key: _forms[2],
        child: Column(children: [
          TextFormField(
            controller: _address,
            maxLines: 2,
            decoration: InputDecoration(labelText: tr('House / street / area')),
            validator: (v) => (v?.trim().length ?? 0) < 5 ? tr('Enter full address') : null,
          ),
          _gap(),
          if (_cities.isEmpty) _notLoaded(tr('Could not load the city list from the RakshakPay server.')),
          DropdownButtonFormField<City>(
            initialValue: _city,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('City')),
            items: [for (final c in _cities) DropdownMenuItem(value: c, child: Text('${c.name}, ${c.state}'))],
            onChanged: (v) => setState(() => _city = v),
            validator: (v) => v == null ? tr('Select city') : null,
          ),
          _gap(),
          TextFormField(
            controller: _pincode,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('PIN code')),
            validator: (v) => RegExp(r'^[1-9]\d{5}$').hasMatch(v ?? '') ? null : tr('6 digits'),
          ),
        ]),
      );

  Widget _accountStep() => Form(
        key: _forms[3],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'SAVINGS', label: Text(tr('Savings')), icon: const Icon(Icons.savings)),
              ButtonSegment(
                  value: 'CURRENT', label: Text(tr('Current / Merchant')), icon: const Icon(Icons.storefront)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          if (_type == 'CURRENT') ...[
            _gap(),
            TextFormField(
              controller: _business,
              decoration: InputDecoration(labelText: tr('Shop / business name')),
              validator: (v) => (v?.trim().length ?? 0) < 3 ? tr('Required for merchant account') : null,
            ),
          ],
          _gap(),
          if (_branches.isEmpty) _notLoaded(tr('Could not load the branch list from the RakshakPay server.')),
          DropdownButtonFormField<Branch>(
            initialValue: _branch,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('Home branch')),
            items: [
              for (final b in _branches)
                DropdownMenuItem(value: b, child: Text('${b.name}  (${b.ifsc})', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _branch = v),
            validator: (v) => v == null ? tr('Select branch') : null,
          ),
          _gap(),
          TextFormField(
            controller: _deposit,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: tr('Opening cash deposit (fake ₹)'), prefixText: '₹ '),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final p = parsePaise(v);
              if (p == null) return tr('Invalid amount');
              if (p > 10_00_000 * 100) return tr('Max ₹10,00,000');
              return null;
            },
          ),
        ]),
      );

  Widget _security() => Form(
        key: _forms[4],
        child: Column(children: [
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: tr('Login password (min 6 characters)')),
            validator: (v) => (v?.length ?? 0) < 6 ? tr('At least 6 characters') : null,
          ),
          _gap(),
          TextFormField(
            controller: _password2,
            obscureText: true,
            decoration: InputDecoration(labelText: tr('Confirm password')),
            validator: (v) => v != _password.text ? tr('Passwords do not match') : null,
          ),
          _gap(),
          TextFormField(
            controller: _mpin,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('4-digit transaction PIN (MPIN)')),
            validator: _pinValidator,
          ),
          _gap(),
          TextFormField(
            controller: _cardPin,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('4-digit debit card / ATM PIN')),
            validator: _pinValidator,
          ),
        ]),
      );
}

class _AccountCreatedScreen extends StatelessWidget {
  const _AccountCreatedScreen(this.data);
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) => ListTile(
          dense: true,
          title: Text(label),
          subtitle: SelectableText(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              showInfo(context, tr('{label} copied', {'label': label}));
            },
          ),
        );

    final card = data['card_no'] as String;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Account opened')), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 8),
          Text(data['message'], textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Column(children: [
              row(tr('Customer ID (for login)'), data['cif']),
              row(tr('Account number'), data['account_no']),
              row(tr('IFSC'), data['ifsc']),
              row(tr('Branch'), data['branch']['name']),
              row(tr('Debit card'), '${card.substring(0, 4)} ${card.substring(4, 8)} ${card.substring(8, 12)} ${card.substring(12)}'),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => LoginScreen(prefillId: data['cif']))),
            child: Text(tr('Login now')),
          ),
        ],
      ),
    );
  }
}
