import 'package:shared_preferences/shared_preferences.dart';


class WrapperPrefsService {
  static Future<void> setNeedUsernameSetup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('needUsernameSetup', value);
  }
  static Future<bool> getNeedUsernameSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('needUsernameSetup') ?? false;
  }
}

