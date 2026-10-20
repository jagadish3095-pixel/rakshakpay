import 'package:rakshak_core/rakshak_core.dart';

import 'models.dart';

/// App-wide objects, created once.
final api = RakshakApi('crypto');
final location = LocationService(api);
final live = LiveUpdates(api);
final savedLogins = SavedLogins(api);

Future<CryptoProfile> loadProfile() async => CryptoProfile.fromJson(await api.get('/api/crypto/me'));

Future<List<PriceTick>> loadPrices() async =>
    [for (final p in await api.get('/api/crypto/prices') as List) PriceTick.fromJson(p)];

void restartLive() {
  live.stop();
  live.start();
}
