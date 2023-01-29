import 'package:flutter/material.dart';

class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({super.key});

  @override
  State<StatefulWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
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
            color: Colors.blue,
          ),
          // Text field
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Say something...',
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          // Send button
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
