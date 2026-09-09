import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Live WebSocket updates (new tasks, bids, application changes). A singleton
/// that keeps one connection, auto-reconnects, and exposes a broadcast stream
/// of tiny event maps like `{"type": "task.new"}`. Screens react by refetching.
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._();
  factory RealtimeService() => _instance;
  RealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _started = false;
  int _retry = 0; // reconnect backoff step

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Broadcast stream of server events. Multiple screens can listen.
  Stream<Map<String, dynamic>> get events => _controller.stream;

  /// Start (idempotent). Call once after login / at app start.
  void start() {
    if (_started) return;
    _started = true;
    _connect();
  }

  Future<void> _connect() async {
    _reconnectTimer?.cancel();
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      _scheduleReconnect();
      return;
    }
    // http(s)://host:port -> ws(s)://host:port/ws
    final wsBase = ApiService.baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsBase/ws?token=$token');
    WebSocketChannel? channel;
    try {
      channel = WebSocketChannel.connect(uri);
      _channel = channel;
      // The handshake fails ASYNCHRONOUSLY (e.g. 403 on an expired token), and
      // that error surfaces via `ready` — awaiting it here means we catch it
      // instead of it becoming an unhandled exception that floods the log.
      await channel.ready;
    } catch (e) {
      if (kDebugMode) debugPrint('Realtime connect failed: $e');
      try {
        await channel?.sink.close();
      } catch (_) {}
      _channel = null;
      _scheduleReconnect();
      return;
    }

    _retry = 0; // connected — reset backoff
    _sub = channel.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data as String);
          if (decoded is Map) {
            _controller.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          /* ignore malformed frames */
        }
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
      cancelOnError: true,
    );
    _startPing();
  }

  void _startPing() {
    _pingTimer?.cancel();
    // Keepalive so idle proxies don't drop the socket.
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add('ping');
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_started) return;
    _reconnectTimer?.cancel();
    // Exponential backoff (5s → 60s cap): an unreachable server or an expired
    // session no longer hammers a reconnect every 5s. A successful connect
    // resets the step, so normal drops still recover quickly.
    final secs = (5 * (1 << _retry)).clamp(5, 60).toInt();
    if (_retry < 4) _retry++;
    _reconnectTimer = Timer(Duration(seconds: secs), _connect);
  }

  void stop() {
    _started = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
