import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';

import '../global.dart';
import 'avatar.dart';

class PersonalDashboard extends StatefulWidget {
  final BiliCredential? cred;

  const PersonalDashboard({super.key, this.cred});

  @override
  State<StatefulWidget> createState() => _PersonalDashboardState();
}

class _PersonalDashboardState extends State<PersonalDashboard>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PersonalInfoAppBar(uid: widget.cred?.uid),
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Change medal (purple)
          _buildActionButton(
            'Change medal',
            Icons.assignment_ind,
            Colors.purple.shade400,
            () {},
          ),
          const SizedBox(height: 8),
          // Battery reward (orange)
          _buildActionButton(
            'Battery reward',
            Icons.battery_charging_full,
            Colors.orange.shade400,
            () {},
          ),
          const SizedBox(height: 8),
          // Daily check in (blue)
          _buildActionButton(
            'Daily check in',
            Icons.event_available,
            Colors.blue.shade400,
            () {},
          ),
        ],
      ),
    );
  }

  ElevatedButton _buildActionButton(
    String text,
    IconData icon,
    Color color,
    void Function()? onPressed,
  ) {
    const buttonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 16);

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: buttonPadding,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

class PersonalInfoAppBar extends StatelessWidget {
  final int? uid;

  const PersonalInfoAppBar({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    var uid_ = uid;
    if (uid_ == null) {
      return AppBar(
        title: Row(
          children: const [
            // TODO: somehow reuse AvatarWidget here?
            CircleAvatar(
              radius: 16,
              // Prevent a strange "border" from appearing around the image
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/noface.gif'),
            ),
            SizedBox(width: 12),
            Text('Not logged in'),
          ],
        ),
      );
    }

    var future = getUserInfo(
      Global.i.dio,
      uid_,
      options: buildCacheOptions(const Duration(days: 3)),
    );
    return AppBar(
      title: Row(
        children: [
          // Avatar
          // TODO: feed UserInfo to AvatarWidget
          AvatarWidget(uid: uid_),
          const SizedBox(width: 12),
          // Nickname
          FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              var data = snapshot.data;
              if (data != null) return _buildNicknameText(data.nickname);

              if (snapshot.hasError) {
                Global.i.logger.e(snapshot.error);
                return _buildNicknameText('Error loading nickname :(');
              }

              return _buildNicknameText('Loading...');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameText(String text) =>
      Text(text, overflow: TextOverflow.ellipsis);
}
