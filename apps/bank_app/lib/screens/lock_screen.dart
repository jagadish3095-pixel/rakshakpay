import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

/// App lock in the bank's colours: asks for the 4-digit MPIN when the app opens
/// or comes back from the background. Five wrong tries log the user out.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onLaunch});

  /// true: app just started (go to Home after unlock). false: resumed (just close the lock).
  final bool onLaunch;

  @override
  Widget build(BuildContext context) {
    return PinLockScreen(
      color: Color.lerp(brand.color, Colors.black, 0.2)!,
      accent: Colors.white,
      logo: BankLogo(brand, size: 80),
      prompt: 'Enter your 4-digit MPIN', // PinLockScreen translates it with tr()
      loadName: () async => (await api.get('/api/me'))['full_name'] as String,
      verify: (pin) => api.post('/api/unlock', {'mpin': pin}),
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
