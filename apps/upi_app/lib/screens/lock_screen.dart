import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

/// App lock: asks for the 4-digit passcode when the app opens or comes back
/// from the background. Five wrong tries log the user out.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onLaunch});

  /// true: app just started (go to Home after unlock). false: resumed (just close the lock).
  final bool onLaunch;

  @override
  Widget build(BuildContext context) {
    return PinLockScreen(
      color: kIndigo,
      accent: kSaffron,
      logo: const RakshakLogo(size: 72, onDark: true),
      prompt: 'Enter your 4-digit passcode',
      loadName: () async => (await loadProfile()).name,
      verify: (pin) => api.post('/api/upi/unlock', {'passcode': pin}),
      onUnlocked: () => onLaunch
          ? Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()))
          : Navigator.pop(context),
      onLogout: ({reason}) async {
        live.stop();
        await api.setToken(null);
        if (!context.mounted) return;
        Navigator.of(context)
            .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
        if (reason != null) showError(context, reason);
      },
    );
  }
}
