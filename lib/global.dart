import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dio_throttler/dio_throttler.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform_shim.dart';

class Global {
  static late final Global i;

  final Logger logger = Logger();
  final Dio dio = Dio();
  late final SharedPreferences prefs;

  static Future<void> init() async {
    // Apply platfrom-specific shims
    platformInit();

    i = Global();

    i.prefs = await SharedPreferences.getInstance();
    installClientConfig(i.dio);
    i.dio.interceptors.addAll([
      DioCacheManager(CacheConfig()).interceptor,
      DioThrottler(const Duration(milliseconds: 500)),
    ]);
  }
}
