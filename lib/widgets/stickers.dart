import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';

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
  static const double height = 800;

  TabController? _tabController;
  List<StickerPack>? _packs;
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
              for (var pack in packs) Center(child: Text(pack.name)),
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

      _tabController = TabController(length: packs.length, vsync: this);
      setState(() {
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
