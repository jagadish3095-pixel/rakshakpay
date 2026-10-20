import 'package:flutter/material.dart';

import 'api.dart';

/// Full-screen PIN pad shown when an app opens or returns from the background.
/// Used by the bank apps (MPIN) and the UPI app (passcode).
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({
    super.key,
    required this.color,
    required this.accent,
    required this.logo,
    required this.prompt,
    required this.verify,
    required this.onUnlocked,
    required this.onLogout,
    this.loadName,
    this.maxTries = 5,
  });

  final Color color, accent;
  final Widget logo;
  final String prompt; // e.g. 'Enter your 4-digit MPIN'

  /// Checks the PIN with the server; throws ApiException if wrong.
  final Future<void> Function(String pin) verify;
  final VoidCallback onUnlocked;
  final Future<void> Function({String? reason}) onLogout;
  final Future<String?> Function()? loadName;
  final int maxTries;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _entered = '';
  String? _name;
  String? _error;
  int _wrong = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Loading the name also checks that the saved login still exists on the server.
    // If it does not (e.g. the demo was reset), skip the PIN and go straight to log in.
    widget.loadName?.call().then((n) {
      if (mounted) setState(() => _name = n);
    }, onError: (Object e) {
      if (mounted && e is ApiException && e.statusCode == 401) widget.onLogout();
    });
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
      await widget.verify(_entered);
      if (mounted) widget.onUnlocked();
    } on ApiException catch (e) {
      // The login itself expired: the PIN cannot help, so go to the login screen.
      if (e.statusCode == 401 && e.message == 'Please log in again') return widget.onLogout();
      if (e.statusCode == 401) {
        _wrong++;
        if (_wrong >= widget.maxTries) {
          return widget.onLogout(reason: 'Too many wrong attempts. Please log in again.');
        }
      }
      if (!mounted) return;
      setState(() {
        _entered = '';
        _error = e.statusCode == 401 ? '${e.message}. ${widget.maxTries - _wrong} tries left.' : e.message;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // the back button must not skip the lock
      child: Scaffold(
        backgroundColor: widget.color,
        body: SafeArea(
          child: Column(children: [
            const Spacer(),
            widget.logo,
            const SizedBox(height: 16),
            Text(_name == null ? 'Welcome back' : 'Welcome back, ${_name!.split(' ').first}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(widget.prompt, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _entered.length ? widget.accent : Colors.transparent,
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                ),
            ]),
            SizedBox(
              height: 48,
              child: Center(
                child: _checking
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD2CC))),
              ),
            ),
            const Spacer(),
            _Keypad(
              onDigit: _press,
              onDelete: () {
                if (_entered.isNotEmpty) setState(() => _entered = _entered.substring(0, _entered.length - 1));
              },
            ),
            TextButton(
              onPressed: () => widget.onLogout(),
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
              child: Center(child: child ?? Text(label, style: const TextStyle(color: Colors.white, fontSize: 28))),
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

/// Watches the app going to the background and shows the lock when it comes
/// back after [lockAfter]. Create one in the root widget's initState.
class AutoLock with WidgetsBindingObserver {
  AutoLock({required this.navigatorKey, required this.isLoggedIn, required this.lockScreen,
      this.lockAfter = const Duration(seconds: 30)}) {
    WidgetsBinding.instance.addObserver(this);
  }

  final GlobalKey<NavigatorState> navigatorKey;
  final bool Function() isLoggedIn;
  final Widget Function() lockScreen;
  final Duration lockAfter;
  DateTime? _backgroundSince;
  bool _shown = false;

  void dispose() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundSince = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundSince;
      _backgroundSince = null;
      if (since != null && isLoggedIn() && !_shown && DateTime.now().difference(since) > lockAfter) _show();
    }
  }

  Future<void> _show() async {
    _shown = true;
    await navigatorKey.currentState?.push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => lockScreen()));
    _shown = false;
  }
}
