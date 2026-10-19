import 'package:rakshak_core/rakshak_core.dart';

import 'announcer.dart';

/// App-wide objects, created once. The merchant logs in with their RakshakPay
/// (UPI) mobile number and passcode.
final api = RakshakApi('merchant');
final location = LocationService(api);
final live = LiveUpdates(api);
final savedLogins = SavedLogins(api);
final announcer = Announcer();

Future<UpiProfile> loadProfile() async => UpiProfile.fromJson(await api.get('/api/upi/me'));

void restartLive() {
  live.stop();
  live.start();
}
