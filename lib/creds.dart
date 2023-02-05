import 'dart:convert';

import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'platform_shim.dart' show getPlatformMonospacedFont;

class BiliCredsProvider extends ChangeNotifier {
  final SharedPreferences _prefs = Global.i.prefs;
  String _json = '';
  BiliCredential? _credential;
  // For the (sole) sake of convenience, we put this flag here.
  bool _simulateSend = false;

  BiliCredential? get credential => _credential;

  /// In simulation mode, messages are never sent to the server, but instead
  /// only printed to the debug console.
  bool get simulateSend => _simulateSend;

  BiliCredsProvider() {
    _json = _prefs.getString('cookies') ?? '';
    _simulateSend = _prefs.getBool('simulate_send') ?? false;

    if (_json.isNotEmpty) {
      _setCredsFrom(_json);
    }
  }

  void _setCredsFrom(String json) {
    var obj = jsonDecode(json);
    _credential = BiliCredential(
      sessdata: obj['SESSDATA'],
      biliJct: obj['bili_jct'],
      buvid3: obj['buvid3'],
      uid: obj['uid'],
    );
    notifyListeners();
  }

  Future<void> toggleSimulateSend() async {
    _simulateSend = !_simulateSend;
    notifyListeners();
    await _prefs.setBool('simulate_send', _simulateSend);
  }

  /// Show an AlertDialog that allows the user to edit the cookie JSON.
  Future<void> showEditDialog(BuildContext context) async {
    var textController = TextEditingController(text: _json);
    bool error = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set cookie JSON'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error
                    ? 'The JSON you have typed is not valid, please try again.'
                    : '',
                style: const TextStyle(color: Colors.red),
              ),
              TextField(
                controller: textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: TextStyle(fontFamily: getPlatformMonospacedFont()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                var json = textController.text;
                try {
                  _setCredsFrom(json);
                } catch (e) {
                  Global.i.logger.w(e);
                  setState(() {
                    error = true;
                  });
                  return;
                }

                Navigator.pop(context);
                _json = json;
                await _prefs.setString('cookies', json);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    // This sometimes causes a use-after-free because of race conditions. Sad :(
    // Let's try to delay for 0 ms to fix that.
    await Future.delayed(Duration.zero, () => textController.dispose());
  }
}
