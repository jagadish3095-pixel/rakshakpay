import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'login_screen.dart';
import 'soundbox_screen.dart';

/// Same RakshakPay passcode as the UPI app.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onLaunch});
  final bool onLaunch;

  @override
  Widget build(BuildContext context) {
    return PinLockScreen(
      color: kIndigo,
      accent: kSaffron,
      logo: const RakshakLogo(size: 72, onDark: true),
      prompt: tr('Enter your RakshakPay passcode'),
      loadName: () async => (await loadProfile()).name,
      verify: (pin) => api.post('/api/upi/unlock', {'passcode': pin}),
      onUnlocked: () => onLaunch
          ? Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SoundboxScreen()))
          : Navigator.pop(context),
      onLogout: ({reason}) async {
        live.stop();
        await api.setToken(null);
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        if (reason != null) showError(context, reason);
      },
    );
  }
}
