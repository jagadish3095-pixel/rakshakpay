import 'dart:convert';

import 'api.dart';

class SavedLogin {
  SavedLogin(this.loginId, this.password, this.name);
  final String loginId, password, name;

  Map<String, String> toJson() => {'id': loginId, 'password': password, 'name': name};
}

/// "Remember me" logins kept on this phone, so demo users can switch with one tap.
///
/// DEMO ONLY: passwords are stored unencrypted. A real bank app would never do this;
/// it would use a device-bound token unlocked by fingerprint or MPIN instead.
class SavedLogins {
  SavedLogins(this.api);
  final RakshakApi api;

  String get _key => '${api.appKey}.saved_logins';

  List<SavedLogin> all() {
    final raw = api.prefs.getString(_key);
    if (raw == null) return [];
    return [
      for (final m in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
        SavedLogin(m['id'], m['password'], m['name']),
    ];
  }

  Future<void> save(SavedLogin login) async {
    final list = all()..removeWhere((l) => l.loginId == login.loginId);
    await _write([login, ...list]);
  }

  /// After a password/passcode change, keep the one-tap login working.
  Future<void> updatePassword(String loginId, String password) async {
    final list = all();
    final i = list.indexWhere((l) => l.loginId == loginId);
    if (i < 0) return;
    list[i] = SavedLogin(loginId, password, list[i].name);
    await _write(list);
  }

  Future<void> remove(String loginId) async {
    await _write(all()..removeWhere((l) => l.loginId == loginId));
  }

  Future<void> _write(List<SavedLogin> list) =>
      api.prefs.setString(_key, jsonEncode([for (final l in list) l.toJson()]));
}
