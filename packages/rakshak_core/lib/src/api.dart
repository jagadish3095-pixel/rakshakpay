import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// An error message from the server that can be shown to the user.
class ApiException implements Exception {
  ApiException(this.message, [this.statusCode = 0]);
  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

/// Talks to the RakshakPay backend running on the laptop.
///
/// Every app creates one of these with its own [appKey] so that, for example,
/// the Sahyadri and Ganga bank apps keep separate logins on the same phone.
class RakshakApi {
  RakshakApi(this.appKey);

  final String appKey;
  late SharedPreferences _prefs;
  String baseUrl = '';
  String? token;

  /// Can be baked in at build time: --dart-define=SERVER=http://192.168.1.7:8000
  static const _buildServer = String.fromEnvironment('SERVER');

  static String get defaultUrl => _buildServer.isNotEmpty
      ? _buildServer
      // The Android emulator reaches the laptop at 10.0.2.2.
      : (kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000');

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    baseUrl = _prefs.getString('server_url') ?? defaultUrl;
    token = _prefs.getString('$appKey.token');
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString('server_url', baseUrl);
  }

  Future<void> setToken(String? value) async {
    token = value;
    if (value == null) {
      await _prefs.remove('$appKey.token');
    } else {
      await _prefs.setString('$appKey.token', value);
    }
  }

  SharedPreferences get prefs => _prefs;

  String get wsUrl => '${baseUrl.replaceFirst('http', 'ws')}/ws?token=$token';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, [Map<String, String>? query]) =>
      _send(() => http.get(Uri.parse('$baseUrl$path').replace(queryParameters: query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(
      () => http.post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response res;
    try {
      // The free cloud server sleeps when unused and needs up to a minute to wake up.
      res = await call().timeout(const Duration(seconds: 75));
    } catch (_) {
      throw ApiException('Cannot reach the RakshakPay server at $baseUrl. '
          'Check your internet connection and the server address in Settings.');
    }
    final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(_errorText(body), res.statusCode);
  }

  /// FastAPI errors are either {"detail": "text"} or a list of field errors.
  static String _errorText(dynamic body) {
    final detail = body is Map ? body['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first as Map;
      final field = (first['loc'] as List?)?.last;
      final msg = (first['msg'] as String? ?? 'Invalid value').replaceFirst('Value error, ', '');
      return field is String ? '${_pretty(field)}: $msg' : msg;
    }
    return 'Something went wrong. Please try again.';
  }

  static String _pretty(String field) =>
      field.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase());
}
