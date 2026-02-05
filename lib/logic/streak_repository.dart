import '../models/app_stats.dart';
import '../models/streak_data.dart';
import '../storage/check_in_storage.dart';

String todayKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

class DateOnly implements Comparable<DateOnly> {
  const DateOnly(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;

  static DateOnly parse(String yyyyMMdd) {
    final p = yyyyMMdd.split('-');
    return DateOnly(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  DateOnly addDays(int delta) {
    final d = DateTime(year, month, day).add(Duration(days: delta));
    return DateOnly(d.year, d.month, d.day);
  }

  @override
  int compareTo(DateOnly other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateOnly &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// Computes longest consecutive streak from sorted list of sober dates.
int bestStreakFromSoberDates(List<String> sorted) {
  if (sorted.isEmpty) return 0;
  final list = sorted.map(DateOnly.parse).toList();
  int best = 1;
  int current = 1;
  for (int i = 1; i < list.length; i++) {
    final prev = list[i - 1].addDays(1);
    if (list[i].year == prev.year &&
        list[i].month == prev.month &&
        list[i].day == prev.day) {
      current++;
    } else {
      current = 1;
    }
    if (current > best) best = current;
  }
  return best;
}

/// Current streak: consecutive sober days ending today. Returns streak count and ordered list of dates.
({int count, String? startDate, List<String> dates}) currentStreakFromSoberDates(
    List<String> soberDates) {
  final today = todayKey();
  final set = soberDates.map(DateOnly.parse).toSet();
  final todayDate = DateOnly.parse(today);
  if (!set.contains(todayDate)) {
    return (count: 0, startDate: null, dates: <String>[]);
  }
  int count = 0;
  while (set.contains(todayDate.addDays(-count))) {
    count++;
  }
  final start = todayDate.addDays(-(count - 1));
  String toKey(DateOnly d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final startStr = toKey(start);
  final dates =
      List<String>.generate(count, (i) => toKey(start.addDays(i)));
  return (count: count, startDate: startStr, dates: dates);
}

/// Application logic: check-in state, streak, and stats from [CheckInStorage].
class StreakRepository {
  StreakRepository({CheckInStorage? storage})
      : _storage = storage ?? CheckInStorageImpl();

  final CheckInStorage _storage;

  Future<bool> isAnsweredToday() async {
    final answered = await _storage.getAnsweredDates();
    return answered.contains(todayKey());
  }

  Future<StreakData> getStreakData() async {
    final sober = await _storage.getSoberDates();
    sober.sort();
    final result = currentStreakFromSoberDates(sober);
    return StreakData(
      currentStreak: result.count,
      streakStartDate: result.startDate,
      streakDates: result.dates,
    );
  }

  Future<AppStats> getStats() async {
    final sober = await _storage.getSoberDates();
    final answered = await _storage.getAnsweredDates();
    sober.sort();
    final best = bestStreakFromSoberDates(sober);
    final streakResult = currentStreakFromSoberDates(sober);
    return AppStats(
      daysAlcoholFree: sober.length,
      bestStreak: best,
      checkInsCompleted: answered.length,
      currentRunStarted: streakResult.startDate,
    );
  }

  /// Record today's answer. Idempotent per day.
  Future<void> recordTodayAnswer(bool sober) async {
    await _storage.recordAnswer(todayKey(), sober);
  }
}
