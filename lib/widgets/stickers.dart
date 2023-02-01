import 'dart:math';

import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../global.dart';

class StickerPicker extends StatefulWidget {
  final int roomId;
  final BiliCredential? cred;

  const StickerPicker({super.key, required this.roomId, this.cred});

  @override
  State<StatefulWidget> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker>
    with SingleTickerProviderStateMixin {
  static const double scaleRatio = 0.5;

  final SharedPreferences _prefs = Global.i.prefs;
  TabController? _tabController;
  List<StickerPack>? _packs;
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    if (widget.cred == null) {
      return _buildWarning('You have to be logged in to view room stickers.');
    }

    var packs = _packs;
    if (packs == null) {
      if (_error) {
        return _buildWarning('Failed to load sticker packs');
      }

      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    var tabController = _tabController!;
    return Column(
      children: [
        AppBar(
          // This results in somehow strange UI design, but it works anyway...
          // TODO: maybe use a colored container instead
          title: TabBar(
            controller: tabController,
            tabs: [
              for (var pack in packs) Tab(text: pack.name),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              for (var pack in packs)
                GridView.extent(
                  // TODO: handle packs with no items?? & handle packs without
                  // size constraints (i.e. width == 0 && height == 0)
                  maxCrossAxisExtent: pack.items[0].width * scaleRatio,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (var item in pack.items)
                      InkWell(
                        onTap: () {
                          // Close the drawer, returning the sticker ID to the caller
                          Navigator.of(context).pop(item.id);
                        },
                        child: CachedNetworkImage(
                          imageUrl: item.url,
                          width: item.width * scaleRatio,
                          height: item.height * scaleRatio,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Center _buildWarning(String msg) {
    return Center(
      child: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.warning, size: 16),
          Text(msg),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    var cred = widget.cred;
    if (cred != null) {
      _loadStickerPacks(cred);
    }
  }

  Future<void> _loadStickerPacks(BiliCredential cred) async {
    try {
      var packs = await getStickerPacksInRoom(
        Global.i.dio,
        widget.roomId,
        cred,
        options: buildCacheOptions(const Duration(days: 7)),
      );

      // Only show official and room-specific stickers (emojis are not
      // supported yet)
      packs = packs
          .where((pack) => pack.type == 1 || pack.type == 2)
          .toList(growable: false);

      // Initialize tab controller
      var tabController = TabController(length: packs.length, vsync: this);
      // Save and restore current tab index
      tabController.index =
          min(_prefs.getInt('stickers_tab_index') ?? 0, tabController.length);
      tabController.addListener(() {
        _prefs.setInt('stickers_tab_index', tabController.index);
      });

      // Update UI
      setState(() {
        _tabController = tabController;
        _packs = packs;
      });
    } catch (e) {
      Global.i.logger.e(e);
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }
}
