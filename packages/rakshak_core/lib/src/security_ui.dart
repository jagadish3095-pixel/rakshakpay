import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets.dart';

/// Change a password or PIN: current value, new value, confirm.
/// [pinDigits] = 4 for PINs/passcodes, null for a password (min 6 characters).
/// Pops with the new value after [submit] succeeds.
class ChangeSecretScreen extends StatefulWidget {
  const ChangeSecretScreen({
    super.key,
    required this.title,
    required this.what, // e.g. 'MPIN', 'UPI PIN', 'password'
    required this.submit,
    this.pinDigits = 4,
    this.help,
  });

  final String title, what;
  final int? pinDigits;
  final String? help;
  final Future<void> Function(String current, String next) submit;

  @override
  State<ChangeSecretScreen> createState() => _ChangeSecretScreenState();
}

class _ChangeSecretScreenState extends State<ChangeSecretScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  bool get _isPin => widget.pinDigits != null;

  String? _validNew(String? v) {
    v ??= '';
    if (_isPin && !RegExp('^\\d{${widget.pinDigits}}\$').hasMatch(v)) return 'Enter ${widget.pinDigits} digits';
    if (!_isPin && v.length < 6) return 'At least 6 characters';
    if (v == _current.text) return 'Must be different from the current ${widget.what}';
    if (_isPin && RegExp(r'^(\d)\1+$').hasMatch(v)) return 'Too easy to guess (all the same digit)';
    if (_isPin && '0123456789'.contains(v)) return 'Too easy to guess (a sequence)';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.submit(_current.text, _new.text);
      if (!mounted) return;
      showInfo(context, '${widget.what[0].toUpperCase()}${widget.what.substring(1)} changed');
      Navigator.pop(context, _new.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  TextFormField _field(TextEditingController c, String label, String? Function(String?) validator) => TextFormField(
        controller: c,
        obscureText: true,
        maxLength: widget.pinDigits,
        keyboardType: _isPin ? TextInputType.number : TextInputType.visiblePassword,
        inputFormatters: _isPin ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (widget.help != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(widget.help!)),
          _field(_current, 'Current ${widget.what}', (v) => (v ?? '').isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          _field(_new, 'New ${widget.what}', _validNew),
          const SizedBox(height: 12),
          _field(_confirm, 'Confirm new ${widget.what}', (v) => v != _new.text ? 'Does not match' : null),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Change ${widget.what}'),
          ),
          const SizedBox(height: 12),
          Text('Never share your ${widget.what} with anyone, including callers who say they are from the bank, '
              'police or RBI.', style: const TextStyle(color: Colors.black54)),
        ]),
      ),
    );
  }
}

/// Types the "/" in a card expiry (MM/YY) automatically.
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length <= 2 ? digits : '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(2, 4))}';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
