import 'dart:collection';

import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../global.dart';
import 'widgets.dart';

/// Provider of message streams in a bilibili live room.
class MessageProvider extends ChangeNotifier {
  final int roomId;
  final List<ChatListItem> _messages = [];
  String? _host;
  int? _port;
  String? _token;

  final Logger _logger = Global.i.logger;
  final SharedPreferences _prefs = Global.i.prefs;

  UnmodifiableListView<ChatListItem> get messages =>
      UnmodifiableListView(_messages);

  MessageProvider(this.roomId);

  Future<void> run() async {
    _logger.d('MessageProvider for room $roomId started');

    // Get WebSocket server configuration from preferences
    _host = _prefs.getString('wss_host');
    _port = _prefs.getInt('wss_port');
    _token = _prefs.getString('token_$roomId');
    if (_host == null || _port == null || _token == null) {
      _logger.d(
        'Missing WebSocket server configuration for room $roomId, updating',
      );
      await _renewWsServerConfig();
    }

    // Connect to WebSocket server
    var server = BililiveSocket(
        host: _host!, port: _port!, roomId: roomId, token: _token!);
    var stream = server.run();

    // Get last 10 messages
    var last10 = await getLast10Messages(Global.i.dio, roomId);
    _messages.addAll(last10.item1.map((msg) => MessageItem(msg)));
    _messages.addAll(last10.item2.map((msg) => MessageItem(msg)));
    notifyListeners();

    // Start receiving from WebSocket
    await for (var msg in stream) {
      var cmd = msg['cmd'] as String;
      if (cmd.startsWith('DANMU_MSG')) {
        _messages.add(MessageItem(Message.fromWebSocketJson(msg['info'])));
        notifyListeners();
      }
    }

    _logger.w('WebSocket stream has been terminated');
    Global.i.eventBus.fire(RoomConnectionLossEvent(roomId));
  }

  /// Fetch WebSocket server configuration from RESTful API.
  Future<void> _renewWsServerConfig() async {
    var server = await getWsServerConfig(Global.i.dio, roomId);
    _host = server.hosts[0].host;
    _port = server.hosts[0].wssPort;
    _token = server.token;
    _logger.d('Got WebSocket host: $_host');

    await Future.wait([
      _prefs.setString('wss_host', _host!),
      _prefs.setInt('wss_port', _port!),
      _prefs.setString('token_$roomId', _token!),
    ]);
  }
}

class RoomConnectionLossEvent {
  final int roomId;

  RoomConnectionLossEvent(this.roomId);
}
