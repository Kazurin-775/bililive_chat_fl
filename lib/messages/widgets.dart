import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:flutter/material.dart';

import '../widgets/message.dart';

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

class ReconnectionHintItem implements ChatListItem {
  @override
  Widget asWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info, size: 20, color: Colors.grey),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Reconnected. Some messages may have been lost at this point.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}
