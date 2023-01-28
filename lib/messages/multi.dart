import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'provider.dart';
import 'widgets.dart';

/// It seems very hard to restart a single MessageProvider (since futures
/// cannot be properly cancelled in Dart).
///
/// So I made this... a strange workaround. This wastes some resources, but
/// that should be fine for people who needs this feature.
class MultiRoomProvider extends ChangeNotifier {
  final Map<int, MessageProvider> _rooms = {};
  int _current;

  int get current => _current;
  UnmodifiableListView<ChatListItem> get messages =>
      _rooms[_current]?.messages ?? UnmodifiableListView([]);

  MultiRoomProvider(this._current) {
    if (_current != 0) _startRoom(_current);
  }

  void setCurrent(int next) {
    _current = next;
    if (_rooms[next] == null && next != 0) {
      _startRoom(next);
    }
    notifyListeners();
  }

  void _startRoom(int roomId) {
    var provider = MessageProvider(roomId);
    provider.addListener(() {
      if (_current == roomId) notifyListeners();
    });
    provider.run();
    _rooms[roomId] = provider;
  }
}
