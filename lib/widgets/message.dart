import 'package:badges/badges.dart';
import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../utils.dart';
import 'avatar.dart';

class MessageWidget extends StatefulWidget {
  static const stickerScale = 0.27;

  final Message message;

  const MessageWidget({super.key, required this.message});

  @override
  State<StatefulWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool _timestampVisible = false;

  Message get message => widget.message;

  @override
  Widget build(BuildContext context) {
    return _attachMouseEventsTo(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          // Align avatars to the top
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            AvatarWidget(uid: message.uid),
            // Horizontal space
            const SizedBox(width: 10),
            // Nickname and content
            Expanded(
              child: Column(
                // Align texts to the left
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SenderInfoWidget(
                    message: message,
                    timestampVisible: _timestampVisible,
                  ),
                  const SizedBox(height: 4),
                  _buildContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      context,
    );
  }

  Widget _buildContent() {
    var sticker = message.sticker;
    if (sticker != null) {
      return CachedNetworkImage(
        imageUrl: sticker.imageUrl,
        width: sticker.width * MessageWidget.stickerScale,
        height: sticker.height * MessageWidget.stickerScale,
      );
    }
    return Text(message.text);
  }

  Widget _attachMouseEventsTo(Widget child, BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Message details'),
            content: Text(_messageDetails()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
      },
      onHover: (hover) => setState(() {
        _timestampVisible = hover;
      }),
      child: child,
    );
  }

  String _messageDetails() =>
      'Sender: ${message.nickname} (UID: ${message.uid})\n'
      'Medal: ${_medalDetails()}\n'
      'Timestamp: ${message.timestamp}';

  String _medalDetails() {
    var medal = message.medal;
    if (medal == null) return '(None)';
    return '${message.medal?.title} Lv. ${message.medal?.level} (${message.medal?.owner})';
  }
}

/// Sender info widget (including nickname, icons (badges) and medal).
class SenderInfoWidget extends StatelessWidget {
  final Message message;
  final bool timestampVisible;

  const SenderInfoWidget({
    super.key,
    required this.message,
    required this.timestampVisible,
  });

  Color _kanchouColor(int lv) {
    if (lv == 0) return Colors.grey;
    if (lv >= 3) return Colors.blue.shade800;
    if (lv == 2) return Colors.purple.shade700;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[
      // Nickname
      Text(
        message.nickname,
        style: TextStyle(
          color: _kanchouColor(message.kanchouLv),
          fontSize: 13,
          fontWeight:
              message.kanchouLv > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ];

    // Kanchou icon (CNY sign)
    if (message.kanchouLv > 0) {
      items.add(FaIcon(
        FontAwesomeIcons.yenSign,
        size: 12,
        color: _kanchouColor(message.kanchouLv),
      ));
    }

    // Medal bubble
    var medal = message.medal;
    if (medal != null) {
      items.add(MedalWidget(medal: medal));
    }

    // Message timestamp
    items.add(FadingWidget(
      visible: timestampVisible,
      duration: const Duration(milliseconds: 200),
      child: TimestampWidget(timestamp: message.timestamp),
    ));

    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }
}

/// Medal bubble (implemented using Material "badge" widget).
class MedalWidget extends StatelessWidget {
  final Medal medal;

  const MedalWidget({super.key, required this.medal});

  @override
  Widget build(BuildContext context) {
    return Badge(
      badgeContent: Text(
        '${medal.title} ${medal.level}',
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
      badgeStyle: BadgeStyle(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: BadgeShape.square,
        borderRadius: BorderRadius.circular(11),
        badgeColor: Color.fromARGB(255, medal.color >> 16,
            (medal.color >> 8) & 255, medal.color & 255),
      ),
      // toAnimate: false,
      badgeAnimation: const BadgeAnimation.fade(),
    );
  }
}

class TimestampWidget extends StatelessWidget {
  final DateTime timestamp;

  const TimestampWidget({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FaIcon(
          FontAwesomeIcons.clock,
          size: 10,
          color: Colors.grey,
        ),
        const SizedBox(width: 3),
        Text(
          '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:'
          '${timestamp.second.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
