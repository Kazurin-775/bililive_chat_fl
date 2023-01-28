import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:flutter/material.dart';

abstract class ChatListItem {
  Widget asWidget();
}

class MessageItem implements ChatListItem {
  final Message msg;

  MessageItem(this.msg);

  @override
  Widget asWidget() {
    return Text('${msg.nickname} says: ${msg.text}');
  }
}
