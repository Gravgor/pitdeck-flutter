import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pitdeck/models/drop.dart';

class CacheService {
  static const String _dropsKey = 'cached_drops';
  static const String _initialLoadKey = 'initial_load';
  static final CacheService _instance = CacheService._internal();
  SharedPreferences? _prefs;

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  Future<SharedPreferences> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> cacheDrops(Map<String, DropModel> drops) async {
    final prefs = await SharedPreferences.getInstance();
    final dropsJson =
        json.encode(drops.map((key, value) => MapEntry(key, value.toMap())));
    await prefs.setString(_dropsKey, dropsJson);
  }

  Future<Map<String, DropModel>> getCachedDrops() async {
    final prefs = await SharedPreferences.getInstance();
    final dropsJson = prefs.getString(_dropsKey);
    if (dropsJson != null) {
      final Map<String, dynamic> decoded = json.decode(dropsJson);
      return decoded
          .map((key, value) => MapEntry(key, DropModel.fromJson(value)));
    }
    return {};
  }

  Future<void> setInitialLoad(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initialLoadKey, value);
  }

  Future<bool> getInitialLoad() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_initialLoadKey) ?? true;
  }

  Future<void> removeDrop(String dropId) async {
    final drops = await getCachedDrops();
    drops.remove(dropId);
    await cacheDrops(drops);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dropsKey);
    await prefs.remove(_initialLoadKey);
  }
}
