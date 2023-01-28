import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'global.dart';

class AvatarWidget extends StatelessWidget {
  static const placeholderImage = AssetImage('assets/noface.gif');

  final int uid;

  const AvatarWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchAvatarUrl(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CachedNetworkImage(
            imageUrl: snapshot.data!,
            imageBuilder: (context, imageProvider) =>
                _buildForImage(imageProvider),
            placeholder: (context, url) => _buildForImage(placeholderImage),
          );
        }
        if (snapshot.hasError) {
          Global.i.logger.w('Failed to load avatar for UID $uid');
        }
        // NetworkImage('https://static.hdslb.com/images/member/noface.gif'),
        return _buildForImage(placeholderImage);
      },
    );
  }

  CircleAvatar _buildForImage(ImageProvider<Object> image) {
    return CircleAvatar(
      radius: 16,
      // Prevent a strange "border" from appearing around the image
      backgroundColor: Colors.transparent,
      backgroundImage: image,
    );
  }

  Future<String> _fetchAvatarUrl() async {
    var cachedUserInfo = await getCachedUserInfo(uid, Global.i.apiCache);
    if (cachedUserInfo != null) return cachedUserInfo.avatarUrl;

    Global.i.logger.d('User info cache miss for UID $uid');
    var userInfo = await Global.i.apiQueue.add(() => getUserInfo(
          Global.i.dio,
          uid,
          cache: Global.i.apiCache,
        ));
    return userInfo.avatarUrl;
  }
}
