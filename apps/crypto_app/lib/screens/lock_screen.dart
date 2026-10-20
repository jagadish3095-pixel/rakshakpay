import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
import '../services.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onLaunch});
  final bool onLaunch;

  @override
  Widget build(BuildContext context) {
    return PinLockScreen(
      color: kBg,
      accent: kGold,
      logo: const CoinVaultLogo(size: 80),
      prompt: 'Enter your 4-digit CoinVault PIN',
      loadName: () async => (await loadProfile()).name,
      verify: (pin) => api.post('/api/crypto/unlock', {'pin': pin}),
      onUnlocked: () => onLaunch
          ? Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()))
          : Navigator.pop(context),
      onLogout: ({reason}) async {
        live.stop();
        await api.setToken(null);
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
        if (reason != null) showError(context, reason);
      },
    );
  }
}
