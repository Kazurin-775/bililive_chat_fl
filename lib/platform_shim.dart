import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Perform platform-specific initialization, in order to fix some defects in
/// third-party libraries.
void platformInit() {
  if (Platform.isWindows || Platform.isLinux) {
    // Manually initialize sqflite on Windows and Linux, for use by
    // `dio_http_cache`.
    // https://github.com/tekartik/sqflite/issues/746
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (Platform.isAndroid) {
    // Manually initialize `WidgetsFlutterBinding` for use by
    // `SharedPreferences`.
    // https://stackoverflow.com/questions/67798798
    WidgetsFlutterBinding.ensureInitialized();
  }
}

String? getPlatformDefaultFont() {
  if (Platform.isWindows) return 'Microsoft YaHei UI';
  return null;
}

String? getPlatformMonospacedFont() {
  if (Platform.isWindows) return 'Consolas';
  return null;
}
