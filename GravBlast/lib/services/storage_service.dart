import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  Future<void> saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }
  
  Future<int?> getInt(String key) async {
    return _prefs?.getInt(key);
  }
  
  Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }
  
  // Check if user has completed tutorial
  Future<bool> hasTutorialCompleted() async {
    return await getBool('tutorial_completed') ?? false;
  }

  // Mark tutorial as completed
  Future<void> setTutorialCompleted() async {
    await saveBool('tutorial_completed', true);
  }

  // Reset tutorial status (for testing)
  Future<void> resetTutorial() async {
    await saveBool('tutorial_completed', false);
  }

  Future<bool?> getBool(String key) async {
    return _prefs?.getBool(key);
  }
  
  Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }
  
  Future<String?> getString(String key) async {
    return _prefs?.getString(key);
  }
  
  Future<void> clear() async {
    await _prefs?.clear();
  }
}