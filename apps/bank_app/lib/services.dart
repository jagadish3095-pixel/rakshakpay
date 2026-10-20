import 'package:rakshak_core/rakshak_core.dart';

import 'brand.dart';

/// App-wide objects, created once in main().
final brand = currentBrand();
final api = RakshakApi('bank.${brand.flavor}');
final location = LocationService(api);
final live = LiveUpdates(api);
final savedLogins = SavedLogins(api);

/// Branch staff log in separately from customers (own token and saved logins).
final officerApi = RakshakApi('bank.${brand.flavor}.officer');
final officerLogins = SavedLogins(officerApi);
