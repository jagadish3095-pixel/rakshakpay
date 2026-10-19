import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

/// App lock: asks for the 4-digit passcode when the app opens or comes back
/// from the background. Five wrong tries log the user out.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onLaunch});

  /// true: app just started (go to Home after unlock). false: resumed (just close the lock).
  final bool onLaunch;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const _maxTries = 5;
  String _entered = '';
  String? _name;
  String? _error;
  int _wrong = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    loadProfile().then((p) {
      if (mounted) setState(() => _name = p.name);
    }, onError: (_) {});
  }

  void _press(String digit) {
    if (_checking || _entered.length == 4) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == 4) _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      await api.post('/api/upi/unlock', {'passcode': _entered});
      if (!mounted) return;
      if (widget.onLaunch) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && e.message == 'Please log in again') return _logout();
      if (e.statusCode == 401) {
        _wrong++;
        if (_wrong >= _maxTries) return _logout(reason: 'Too many wrong passcodes. Please log in again.');
      }
      setState(() {
        _entered = '';
        _error = e.statusCode == 401 ? 'Wrong passcode. ${_maxTries - _wrong} tries left.' : e.message;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logout({String? reason}) async {
    live.stop();
    await api.setToken(null);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
    if (reason != null) showError(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // the back button must not skip the lock
      child: Scaffold(
        backgroundColor: kIndigo,
        body: SafeArea(
          child: Column(children: [
            const Spacer(),
            const RakshakLogo(size: 72, onDark: true),
            const SizedBox(height: 16),
            Text(_name == null ? 'Welcome back' : 'Welcome back, ${_name!.split(' ').first}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Enter your 4-digit passcode', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _entered.length ? kSaffron : Colors.transparent,
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                ),
            ]),
            SizedBox(
              height: 48,
              child: Center(
                child: _checking
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_error ?? '', style: const TextStyle(color: Color(0xFFFFB4A8))),
              ),
            ),
            const Spacer(),
            _Keypad(onDigit: _press, onDelete: () {
              if (_entered.isNotEmpty) setState(() => _entered = _entered.substring(0, _entered.length - 1));
            }),
            TextButton(
              onPressed: () => _logout(),
              child: const Text('Log out / switch user', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onDelete});
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) => Expanded(
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap ?? () => onDigit(label),
            child: SizedBox(
              height: 68,
              child: Center(
                child: child ?? Text(label, style: const TextStyle(color: Colors.white, fontSize: 28)),
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(children: [
        for (final row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
          Row(children: [for (final d in row) key(d)]),
        Row(children: [
          const Expanded(child: SizedBox()),
          key('0'),
          key('', onTap: onDelete, child: const Icon(Icons.backspace_outlined, color: Colors.white)),
        ]),
      ]),
    );
  }
}
