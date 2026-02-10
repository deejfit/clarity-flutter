import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_loader.dart';

const String _keySoberDates = 'sober_dates';
const String _keyAnsweredDates = 'answered_dates';
String _keyDifficulty(String date) => 'check_in_difficulty_$date';
String _keyNote(String date) => 'check_in_note_$date';

/// Optional context for a check-in (analytics only; no effect on streak/stats).
class CheckInExtra {
  const CheckInExtra({this.difficulty, this.note});
  final int? difficulty; // 1-5
  final String? note; // single word, max ~20 chars
}

/// Local persistence for daily check-in: sober dates, answered dates (yyyy-MM-dd), and optional extra.
abstract class CheckInStorage {
  Future<List<String>> getSoberDates();
  Future<List<String>> getAnsweredDates();
  Future<void> recordAnswer(String date, bool sober);
  Future<CheckInExtra> getCheckInExtra(String date);
  Future<void> setCheckInExtra(String date, int? difficulty, String? note);
  /// Batch fetch extras for many dates (e.g. for insights). Returns map date -> extra.
  Future<Map<String, CheckInExtra>> getCheckInExtrasForDates(List<String> dates);
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

  @override
  Future<CheckInExtra> getCheckInExtra(String date) async {
    final prefs = await _instance;
    if (prefs == null) return const CheckInExtra();
    final d = prefs.getInt(_keyDifficulty(date));
    final n = prefs.getString(_keyNote(date));
    return CheckInExtra(
      difficulty: d != null && d >= 1 && d <= 5 ? d : null,
      note: (n != null && n.isNotEmpty) ? n : null,
    );
  }

  @override
  Future<void> setCheckInExtra(String date, int? difficulty, String? note) async {
    final prefs = await _instance;
    if (prefs == null) return;
    if (difficulty != null && difficulty >= 1 && difficulty <= 5) {
      await prefs.setInt(_keyDifficulty(date), difficulty);
    } else {
      await prefs.remove(_keyDifficulty(date));
    }
    if (note != null && note.isNotEmpty) {
      await prefs.setString(_keyNote(date), note.length > 20 ? note.substring(0, 20) : note);
    } else {
      await prefs.remove(_keyNote(date));
    }
  }

  @override
  Future<Map<String, CheckInExtra>> getCheckInExtrasForDates(List<String> dates) async {
    final prefs = await _instance;
    final result = <String, CheckInExtra>{};
    if (prefs == null) return result;
    for (final date in dates) {
      final d = prefs.getInt(_keyDifficulty(date));
      final n = prefs.getString(_keyNote(date));
      result[date] = CheckInExtra(
        difficulty: d != null && d >= 1 && d <= 5 ? d : null,
        note: (n != null && n.isNotEmpty) ? n : null,
      );
    }
    return result;
  }
}
