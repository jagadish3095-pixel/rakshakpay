import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';

/// Listens to the server and reports which account changed, so screens can
/// refresh instantly. Reconnects automatically if Wi-Fi drops.
class LiveUpdates {
  LiveUpdates(this.api);

  final RakshakApi api;
  final _changes = StreamController<String>.broadcast();
  WebSocketChannel? _channel;
  Timer? _ping;
  Timer? _retry;
  bool _running = false;

  /// Emits an account number every time that account's money changes.
  Stream<String> get changes => _changes.stream;

  void start() {
    if (_running || api.token == null) return;
    _running = true;
    _connect();
  }

  void stop() {
    _running = false;
    _ping?.cancel();
    _retry?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void _connect() {
    if (!_running) return;
    final WebSocketChannel channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse(api.wsUrl));
    } catch (_) {
      _scheduleRetry();
      return;
    }
    _channel = channel;
    // A failed connection is reported through `ready`; handle it so it is not an uncaught error.
    channel.ready.then((_) {}, onError: (_) {});
    _ping = Timer.periodic(const Duration(seconds: 20), (_) => _channel?.sink.add('ping'));
    channel.stream.listen(
      (message) {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        if (data['type'] == 'account_changed') _changes.add(data['account_no'] as String);
      },
      onDone: () {
        // 4401 = the server no longer accepts this login; retrying would never succeed.
        if (channel.closeCode == 4401) return stop();
        _scheduleRetry();
      },
      onError: (_) => _scheduleRetry(),
      cancelOnError: true,
    );
  }

  void _scheduleRetry() {
    _ping?.cancel();
    if (!_running) return;
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), _connect);
  }
}
