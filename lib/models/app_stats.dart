/// Statistics derived from local storage. All values from real data.
class AppStats {
  const AppStats({
    required this.daysAlcoholFree,
    required this.bestStreak,
    required this.checkInsCompleted,
    required this.currentRunStarted,
  });

  final int daysAlcoholFree;
  final int bestStreak;
  final int checkInsCompleted;
  final String? currentRunStarted;
}
