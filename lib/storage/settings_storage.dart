import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_loader.dart';

const String _keyNotificationsEnabled = 'notifications_enabled';
const String _keyNotificationHour = 'notification_hour';
const String _keyNotificationMinute = 'notification_minute';

abstract class SettingsStorage {
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool value);
  Future<int> getNotificationHour();
  Future<int> getNotificationMinute();
  Future<void> setNotificationTime(int hour, int minute);
}

class SettingsStorageImpl implements SettingsStorage {
  SettingsStorageImpl({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryFallback = {};

  Future<SharedPreferences?> get _instance async {
    if (_prefs != null) return _prefs;
    _prefs = await getSharedPreferencesSafe();
    return _prefs;
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final prefs = await _instance;
    if (prefs != null) return prefs.getBool(_keyNotificationsEnabled) ?? false;
    return _memoryFallback[_keyNotificationsEnabled] as bool? ?? false;
  }

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _instance;
    if (prefs != null) {
      await prefs.setBool(_keyNotificationsEnabled, value);
    } else {
      _memoryFallback[_keyNotificationsEnabled] = value;
    }
  }

  @override
  Future<int> getNotificationHour() async {
    final prefs = await _instance;
    if (prefs != null) return prefs.getInt(_keyNotificationHour) ?? 9;
    return _memoryFallback[_keyNotificationHour] as int? ?? 9;
  }

  @override
  Future<int> getNotificationMinute() async {
    final prefs = await _instance;
    if (prefs != null) return prefs.getInt(_keyNotificationMinute) ?? 0;
    return _memoryFallback[_keyNotificationMinute] as int? ?? 0;
  }

  @override
  Future<void> setNotificationTime(int hour, int minute) async {
    final prefs = await _instance;
    if (prefs != null) {
      await prefs.setInt(_keyNotificationHour, hour);
      await prefs.setInt(_keyNotificationMinute, minute);
    } else {
      _memoryFallback[_keyNotificationHour] = hour;
      _memoryFallback[_keyNotificationMinute] = minute;
    }
  }
}
