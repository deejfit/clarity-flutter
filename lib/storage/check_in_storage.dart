import 'package:shared_preferences/shared_preferences.dart';

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

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<List<String>> getSoberDates() async {
    final prefs = await _instance;
    final list = prefs.getStringList(_keySoberDates);
    return list ?? [];
  }

  @override
  Future<List<String>> getAnsweredDates() async {
    final prefs = await _instance;
    final list = prefs.getStringList(_keyAnsweredDates);
    return list ?? [];
  }

  @override
  Future<void> recordAnswer(String date, bool sober) async {
    final prefs = await _instance;
    final answered = prefs.getStringList(_keyAnsweredDates) ?? [];
    if (!answered.contains(date)) {
      answered.add(date);
      answered.sort();
      await prefs.setStringList(_keyAnsweredDates, answered);
    }
    if (sober) {
      final soberList = prefs.getStringList(_keySoberDates) ?? [];
      if (!soberList.contains(date)) {
        soberList.add(date);
        soberList.sort();
        await prefs.setStringList(_keySoberDates, soberList);
      }
    }
  }
}
