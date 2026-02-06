import 'package:shared_preferences/shared_preferences.dart';

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

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final prefs = await _instance;
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  @override
  Future<int> getNotificationHour() async {
    final prefs = await _instance;
    return prefs.getInt(_keyNotificationHour) ?? 9;
  }

  @override
  Future<int> getNotificationMinute() async {
    final prefs = await _instance;
    return prefs.getInt(_keyNotificationMinute) ?? 0;
  }

  @override
  Future<void> setNotificationTime(int hour, int minute) async {
    final prefs = await _instance;
    await prefs.setInt(_keyNotificationHour, hour);
    await prefs.setInt(_keyNotificationMinute, minute);
  }
}
