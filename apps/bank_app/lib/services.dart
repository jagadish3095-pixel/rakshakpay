import 'package:rakshak_core/rakshak_core.dart';

import 'brand.dart';

/// App-wide objects, created once in main().
final brand = BankBrand.current();
final api = RakshakApi('bank.${brand.flavor}');
final location = LocationService(api);
final live = LiveUpdates(api);
final savedLogins = SavedLogins(api);
