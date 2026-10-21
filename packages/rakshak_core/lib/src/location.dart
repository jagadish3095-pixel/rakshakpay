import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'api.dart';
import 'app_settings.dart';
import 'models.dart';

/// Where the phone is when a transaction happens.
class TxnLocation {
  TxnLocation(this.lat, this.lng, this.label, this.source);
  final double? lat, lng;
  final String label;
  final String source; // GPS, or '' when unavailable

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'label': label, 'source': source};
}

/// Why the phone's position could not be read.
enum GpsProblem { serviceOff, denied, deniedForever, failed }

/// Reads the phone's GPS position. Payments cannot be made without it: the police use it
/// to see where stolen money was moved from.
class LocationService {
  LocationService(this.api);

  final RakshakApi api;
  List<City> _cities = [];

  Future<List<City>> cities() async {
    if (_cities.isEmpty) {
      final list = await api.get('/api/cities') as List;
      _cities = [for (final c in list) City.fromJson(c)];
    }
    return _cities;
  }

  /// The phone's position, or 'Location unavailable' (used where location is optional,
  /// e.g. filing a complaint). Never throws.
  Future<TxnLocation> current() async => (await _read()).$1 ?? TxnLocation(null, null, 'Location unavailable', '');

  /// For payments: returns the phone's position, or shows a popup explaining that location
  /// is mandatory and returns null. The caller must not make the payment when this is null.
  Future<TxnLocation?> requireForPayment(BuildContext context) async {
    while (true) {
      final (loc, problem) = await _read();
      if (loc != null) return loc;
      if (!context.mounted) return null;
      final retry = await _explain(context, problem!);
      if (!retry || !context.mounted) return null;
    }
  }

  /// Whether this app may read the phone's location (shown in Settings).
  Future<GpsProblem?> check() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return GpsProblem.serviceOff;
      return switch (await Geolocator.checkPermission()) {
        LocationPermission.denied => GpsProblem.denied,
        LocationPermission.deniedForever => GpsProblem.deniedForever,
        _ => null,
      };
    } catch (_) {
      return GpsProblem.failed;
    }
  }

  /// Asks Android for location permission (or opens settings if it was refused for good).
  Future<void> askPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      } else if (await Geolocator.requestPermission() == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
    } catch (_) {}
  }

  /// Latitude/longitude to use for "nearest ATM" lists.
  Future<({double lat, double lng})?> point() async {
    final loc = (await _read()).$1;
    return loc == null ? null : (lat: loc.lat!, lng: loc.lng!);
  }

  Future<(TxnLocation?, GpsProblem?)> _read() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return (null, GpsProblem.serviceOff);
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return (null, GpsProblem.denied);
      if (perm == LocationPermission.deniedForever) return (null, GpsProblem.deniedForever);
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
        );
      } catch (_) {
        // Indoors the GPS can be slow: fall back to the last fix the phone knows.
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return (null, GpsProblem.failed);
      City? near;
      try {
        near = nearestCity(await cities(), pos.latitude, pos.longitude);
      } catch (_) {}
      final label = near == null ? 'GPS location' : 'Near ${near.name}, ${near.state}';
      return (TxnLocation(pos.latitude, pos.longitude, label, 'GPS'), null);
    } catch (_) {
      return (null, GpsProblem.failed);
    }
  }

  /// Popup shown when a payment is stopped for lack of location. Returns true to try again.
  Future<bool> _explain(BuildContext context, GpsProblem problem) async {
    final (message, button) = switch (problem) {
      GpsProblem.serviceOff => (tr('Location (GPS) is turned off on this phone. Turn it on to make payments.'),
          tr('Turn on location')),
      GpsProblem.denied => (tr('This app needs permission to use your location. Tap Allow when Android asks.'),
          tr('Allow location')),
      GpsProblem.deniedForever => (tr('Location permission is blocked for this app. Open App settings > '
          'Permissions > Location and choose Allow.'), tr('Open app settings')),
      GpsProblem.failed => (tr('Could not find your location. Move near a window or outdoors and try again.'),
          tr('Try again')),
    };
    final action = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_off, size: 48, color: Colors.red),
        title: Text(tr('Location is mandatory')),
        content: Text('$message\n\n${tr('Every payment records where it was made, so that money stolen by '
            'fraudsters can be traced. The payment has not been made.')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel payment'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(button)),
        ],
      ),
    );
    if (action != true) return false;
    // Settings open on top of the app; the user taps Pay again when they come back.
    switch (problem) {
      case GpsProblem.serviceOff:
        await Geolocator.openLocationSettings();
        return false;
      case GpsProblem.deniedForever:
        await Geolocator.openAppSettings();
        return false;
      case GpsProblem.denied || GpsProblem.failed:
        return true; // ask Android again / read the GPS again
    }
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
