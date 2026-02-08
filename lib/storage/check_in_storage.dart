import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_loader.dart';

const String _keySoberDates = 'sober_dates';
const String _keyAnsweredDates = 'answered_dates';

/// Local persistence for daily check-in: sober dates and answered dates (yyyy-MM-dd).
abstract class CheckInStorage {
  Future<List<String>> getSoberDates();
  Future<List<String>> getAnsweredDates();
  Future<void> recordAnswer(String date, bool sober);
}

class CheckInStorageImpl implements CheckInStorage {
  CheckInStorageImpl({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  final Map<String, List<String>> _memoryFallback = {};

  Future<SharedPreferences?> get _instance async {
    if (_prefs != null) return _prefs;
    _prefs = await getSharedPreferencesSafe();
    return _prefs;
  }

  @override
  Future<List<String>> getSoberDates() async {
    final prefs = await _instance;
    if (prefs != null) {
      final list = prefs.getStringList(_keySoberDates);
      return list ?? [];
    }
    return List<String>.from(_memoryFallback[_keySoberDates] ?? []);
  }

  @override
  Future<List<String>> getAnsweredDates() async {
    final prefs = await _instance;
    if (prefs != null) {
      final list = prefs.getStringList(_keyAnsweredDates);
      return list ?? [];
    }
    return List<String>.from(_memoryFallback[_keyAnsweredDates] ?? []);
  }

  @override
  Future<void> recordAnswer(String date, bool sober) async {
    final prefs = await _instance;
    final answered = prefs != null
        ? (prefs.getStringList(_keyAnsweredDates) ?? [])
        : List<String>.from(_memoryFallback[_keyAnsweredDates] ?? []);
    if (!answered.contains(date)) {
      answered.add(date);
      answered.sort();
      if (prefs != null) {
        await prefs.setStringList(_keyAnsweredDates, answered);
      } else {
        _memoryFallback[_keyAnsweredDates] = answered;
      }
    }
    if (sober) {
      final soberList = prefs != null
          ? (prefs.getStringList(_keySoberDates) ?? [])
          : List<String>.from(_memoryFallback[_keySoberDates] ?? []);
      if (!soberList.contains(date)) {
        soberList.add(date);
        soberList.sort();
        if (prefs != null) {
          await prefs.setStringList(_keySoberDates, soberList);
        } else {
          _memoryFallback[_keySoberDates] = soberList;
        }
      }
    }
  }
}
