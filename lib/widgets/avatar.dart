import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';

import '../global.dart';

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
                _buildWithImage(imageProvider),
            placeholder: (context, url) => _buildWithImage(placeholderImage),
          );
        }

        if (snapshot.hasError) {
          Global.i.logger.w('Failed to load avatar for UID $uid');
        }
        // NetworkImage('https://static.hdslb.com/images/member/noface.gif'),
        return _buildWithImage(placeholderImage);
      },
    );
  }

  CircleAvatar _buildWithImage(ImageProvider<Object> image) {
    return CircleAvatar(
      radius: 16,
      // Prevent a strange "border" from appearing around the image
      backgroundColor: Colors.transparent,
      backgroundImage: image,
    );
  }

  /// Fetch the URL of the user's avatar image (which is then fed to `CachedNetworkImage`).
  Future<String> _fetchAvatarUrl() async {
    var userInfo = await getUserInfo(
      Global.i.dio,
      uid,
      // Force caching user info for 3 days
      options: buildCacheOptions(const Duration(days: 3)),
    );
    return userInfo.avatarUrl;
  }
}
