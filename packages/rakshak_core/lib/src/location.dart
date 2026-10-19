import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'api.dart';
import 'models.dart';

/// Where the phone is when a transaction happens.
class TxnLocation {
  TxnLocation(this.lat, this.lng, this.label, this.source);
  final double? lat, lng;
  final String label;
  final String source; // GPS | DEMO

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'label': label, 'source': source};
}

/// Gets the phone's location for every transaction.
///
/// During a demo every phone is in the same room, so a "demo city" can be set
/// in Settings to pretend this phone is somewhere else (e.g. Jamtara).
class LocationService {
  LocationService(this.api);

  final RakshakApi api;
  List<City> _cities = [];

  static const _demoCityKey = 'demo_city';

  String? get demoCity => api.prefs.getString(_demoCityKey);

  Future<void> setDemoCity(String? city) async {
    if (city == null) {
      await api.prefs.remove(_demoCityKey);
    } else {
      await api.prefs.setString(_demoCityKey, city);
    }
  }

  Future<List<City>> cities() async {
    if (_cities.isEmpty) {
      final list = await api.get('/api/cities') as List;
      _cities = [for (final c in list) City.fromJson(c)];
    }
    return _cities;
  }

  /// Never throws: if location is unavailable the transaction still goes through.
  Future<TxnLocation> current() async {
    try {
      final all = await cities();
      final demo = demoCity;
      if (demo != null) {
        final c = all.firstWhere((c) => c.name == demo);
        return TxnLocation(c.lat, c.lng, '${c.name}, ${c.state}', 'DEMO');
      }
      final pos = await _gps();
      if (pos == null) return TxnLocation(null, null, 'Location unavailable', '');
      final near = nearestCity(all, pos.latitude, pos.longitude);
      final label = near == null ? 'GPS location' : 'Near ${near.name}, ${near.state}';
      return TxnLocation(pos.latitude, pos.longitude, label, 'GPS');
    } catch (_) {
      return TxnLocation(null, null, 'Location unavailable', '');
    }
  }

  /// Latitude/longitude to use for "nearest ATM" lists.
  Future<({double lat, double lng})?> point() async {
    final loc = await current();
    return loc.lat == null ? null : (lat: loc.lat!, lng: loc.lng!);
  }

  Future<Position?> _gps() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
    );
  }

  static City? nearestCity(List<City> cities, double lat, double lng) {
    City? best;
    var bestKm = double.infinity;
    for (final c in cities) {
      final km = distanceKm(lat, lng, c.lat, c.lng);
      if (km < bestKm) {
        bestKm = km;
        best = c;
      }
    }
    return bestKm < 150 ? best : null;
  }

  /// Straight-line distance between two points on Earth.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(a));
  }
}
