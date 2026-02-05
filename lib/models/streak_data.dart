/// First day of current streak (yyyy-MM-dd), or null if no current streak.
/// Ordered list of dates in the current streak for the strip (oldest to newest).
class StreakData {
  const StreakData({
    required this.currentStreak,
    required this.streakStartDate,
    required this.streakDates,
  });

  final int currentStreak;
  final String? streakStartDate;
  final List<String> streakDates;
}
