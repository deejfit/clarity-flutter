import '../storage/check_in_storage.dart';
import 'streak_repository.dart';

/// Minimum check-ins required to show insights.
const int kMinCheckInsForInsights = 5;

/// Minimum difficulty values (days with a recorded difficulty) required.
const int kMinDifficultyValuesForInsights = 3;

/// One point on the streak difficulty graph: day index (1-based) and difficulty (1-5).
class StreakDifficultyPoint {
  const StreakDifficultyPoint({required this.dayIndex, required this.difficulty});
  final int dayIndex;
  final int difficulty;
}

/// Result of insights calculation. Use [hasSufficientData] to decide what to show.
class InsightsResult {
  const InsightsResult({
    required this.hasSufficientData,
    this.insightTexts = const [],
    this.streakDifficultyPoints = const [],
    this.streakLength = 0,
  });

  final bool hasSufficientData;
  final List<String> insightTexts;
  final List<StreakDifficultyPoint> streakDifficultyPoints;
  final int streakLength;
}

/// Computes pattern insights from local check-in and difficulty data.
/// All logic lives here; UI only displays the result.
class InsightsService {
  InsightsService({CheckInStorage? storage})
      : _storage = storage ?? CheckInStorageImpl();

  final CheckInStorage _storage;

  /// Returns insights result. Never throws; returns safe defaults if data is missing.
  Future<InsightsResult> getInsights() async {
    try {
      final answered = await _storage.getAnsweredDates();
      if (answered.isEmpty) return _insufficient();

      final extrasMap = await _storage.getCheckInExtrasForDates(answered);
      final difficultyCount = extrasMap.values
          .where((e) => e.difficulty != null && e.difficulty! >= 1 && e.difficulty! <= 5)
          .length;

      final hasEnoughCheckIns = answered.length >= kMinCheckInsForInsights;
      final hasEnoughDifficulty = difficultyCount >= kMinDifficultyValuesForInsights;
      if (!hasEnoughCheckIns || !hasEnoughDifficulty) {
        return _insufficient();
      }

      final sober = await _storage.getSoberDates();
      sober.sort();
      final streakResult = currentStreakFromSoberDates(sober);
      if (streakResult.dates.isEmpty) {
        return InsightsResult(
          hasSufficientData: true,
          insightTexts: _insightTextsForNoCurrentStreak(extrasMap, answered.length),
          streakDifficultyPoints: [],
          streakLength: 0,
        );
      }

      final streakExtras = await _storage.getCheckInExtrasForDates(streakResult.dates);
      final points = <StreakDifficultyPoint>[];
      for (var i = 0; i < streakResult.dates.length; i++) {
        final date = streakResult.dates[i];
        final extra = streakExtras[date];
        final d = extra?.difficulty;
        if (d != null && d >= 1 && d <= 5) {
          points.add(StreakDifficultyPoint(dayIndex: i + 1, difficulty: d));
        }
      }

      final insightTexts = _deriveInsightTexts(
        streakLength: streakResult.dates.length,
        points: points,
        totalCheckIns: answered.length,
        totalWithDifficulty: difficultyCount,
      );

      return InsightsResult(
        hasSufficientData: true,
        insightTexts: insightTexts,
        streakDifficultyPoints: points,
        streakLength: streakResult.dates.length,
      );
    } catch (_) {
      return _insufficient();
    }
  }

  InsightsResult _insufficient() {
    return const InsightsResult(
      hasSufficientData: false,
      insightTexts: [],
      streakDifficultyPoints: [],
      streakLength: 0,
    );
  }

  List<String> _insightTextsForNoCurrentStreak(
    Map<String, CheckInExtra> extrasMap,
    int totalCheckIns,
  ) {
    final withDifficulty = extrasMap.values.where((e) => e.difficulty != null).length;
    if (withDifficulty >= 3 && totalCheckIns >= 5) {
      return ['Difficulty varies, but consistency remains.'];
    }
    return [];
  }

  /// Derive 1–2 factual, neutral insight strings from data. No advice or prescriptions.
  List<String> _deriveInsightTexts({
    required int streakLength,
    required List<StreakDifficultyPoint> points,
    required int totalCheckIns,
    required int totalWithDifficulty,
  }) {
    final list = <String>[];
    if (points.isEmpty) {
      if (streakLength >= 2) {
        list.add('Your current streak is $streakLength days.');
      }
      return list;
    }

    final difficulties = points.map((e) => e.difficulty).toList();
    final highCount = difficulties.where((d) => d >= 4).length;
    final maxD = difficulties.reduce((a, b) => a > b ? a : b);
    final minD = difficulties.reduce((a, b) => a < b ? a : b);
    final hasVariation = difficulties.length > 1 && (maxD - minD >= 2);

    if (highCount >= 2 && streakLength >= 2) {
      list.add('Your current streak includes several high-difficulty days.');
    }
    if (highCount >= 1 && streakLength >= 2 && list.length < 2) {
      list.add('Hard days don\'t necessarily break your streak.');
    }
    if (hasVariation && list.length < 2) {
      list.add('Difficulty varies, but consistency remains.');
    }
    if (list.isEmpty && streakLength >= 1) {
      list.add('Your current streak is $streakLength ${streakLength == 1 ? 'day' : 'days'}.');
    }
    return list.take(2).toList();
  }
}
