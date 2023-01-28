import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';
import 'package:queue/queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static late final Global i;

  final Logger logger = Logger();
  final Dio dio = Dio();
  final Queue apiQueue = Queue(delay: const Duration(milliseconds: 500));
  final CacheManager apiCache = CacheManager(Config(
    'bili_api',
    maxNrOfCacheObjects: 2000,
  ));
  late final SharedPreferences prefs;

  static Future<void> init() async {
    i = Global();

    i.prefs = await SharedPreferences.getInstance();
    installClientConfig(i.dio);
  }
}
