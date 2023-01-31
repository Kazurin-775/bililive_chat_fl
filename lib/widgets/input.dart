import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../creds.dart';
import '../global.dart';
import '../messages/multi.dart';

class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({super.key});

  @override
  State<StatefulWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _editController = TextEditingController();
  final FocusNode _textBoxFocusNode = FocusNode();
  bool _sendInProgress = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      // Use a mixture of (a very small portion of) app primary color and light
      // gray to create some contrast between the content zone and the input
      // zone.
      // TODO: any better design choices for this?
      color: Color.alphaBlend(
        Colors.blue.withOpacity(0.15),
        // Theme.of(context).scaffoldBackgroundColor,
        Colors.grey.shade100,
      ),
      child: Row(
        children: [
          // Open emotion / sticker drawer
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.emoji_emotions),
            // Use gray to indicate busy state (but keep the button enabled).
            // TODO: better UX design?
            color: _busy ? Colors.grey : Colors.blue,
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: _editController,
              focusNode: _textBoxFocusNode,
              // Use gray to indicate busy state (but keep the input box enabled).
              style: TextStyle(color: _busy ? Colors.grey : null),
              decoration: const InputDecoration(
                hintText: 'Say something...',
                border: InputBorder.none,
              ),
              onSubmitted: (message) {
                if (message.isNotEmpty) {
                  _onSend(message);
                } else {
                  Global.i.logger.d('Nothing to send');
                }
              },
            ),
          ),
          // Send button
          IconButton(
            // Disable this button when busy
            // TODO: ternary operator results in ugly formatting. How to resolve this?
            onPressed: _busy
                ? null
                : () {
                    var message = _editController.text;
                    if (message.isNotEmpty) {
                      _onSend(message);
                    } else {
                      Global.i.logger.d('Nothing to send');
                    }
                  },
            icon: _busy
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _onSend(String message) async {
    // Prevent re-entrance (is this ever necessary?)
    if (_sendInProgress) return;
    _sendInProgress = true;

    try {
      setState(() {
        _busy = true;
      });

      // Clear input box (to indicate to the user that the app has acknowledged
      // user input)
      _editController.text = '';
      // Re-focus the input box
      _textBoxFocusNode.requestFocus();

      var roomId =
          Provider.of<MultiRoomProvider>(context, listen: false).current;
      var creds = Provider.of<BiliCredsProvider>(context, listen: false);

      if (creds.simulateSend) {
        // Simulate send
        Global.i.logger.i('Send message "$message" to room $roomId');
        await Future.delayed(const Duration(seconds: 1));
      }
    } finally {
      _sendInProgress = false;
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _editController.dispose();
    _textBoxFocusNode.dispose();
  }
}
