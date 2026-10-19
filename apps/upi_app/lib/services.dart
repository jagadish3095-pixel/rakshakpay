import 'package:rakshak_core/rakshak_core.dart';

/// App-wide objects, created once.
final api = RakshakApi('upi');
final location = LocationService(api);
final live = LiveUpdates(api);
final savedLogins = SavedLogins(api);

/// The logged-in user's profile and linked UPI IDs.
Future<UpiProfile> loadProfile() async => UpiProfile.fromJson(await api.get('/api/upi/me'));

/// After logging in or linking a new bank, reconnect live updates so the
/// server knows every account to watch.
void restartLive() {
  live.stop();
  live.start();
}
