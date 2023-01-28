import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:flutter/material.dart';

import 'widget.dart';

abstract class ChatListItem {
  Widget asWidget();
}

class MessageItem implements ChatListItem {
  final Message msg;

  MessageItem(this.msg);

  @override
  Widget asWidget() {
    return MessageWidget(message: msg);
  }
}
