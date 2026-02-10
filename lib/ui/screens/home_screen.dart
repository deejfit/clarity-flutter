import 'package:flutter/material.dart';
import '../../logic/insights_service.dart';
import '../../logic/streak_repository.dart';
import '../../models/app_stats.dart';
import '../../models/streak_data.dart';
import '../widgets/check_in_modal.dart';
import '../widgets/insights_card.dart';
import '../widgets/statistics_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/streak_strip.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StreakRepository _repo = StreakRepository();
  final InsightsService _insightsService = InsightsService();
  StreakData? _streakData;
  AppStats? _stats;
  InsightsResult? _insightsResult;
  bool _answeredToday = false;
  bool _loading = true;

  Future<void> _load() async {
    try {
      final streakData = await _repo.getStreakData();
      final stats = await _repo.getStats();
      final answered = await _repo.isAnsweredToday();
      final insightsResult = await _insightsService.getInsights();
      if (mounted) {
        setState(() {
          _streakData = streakData;
          _stats = stats;
          _insightsResult = insightsResult;
          _answeredToday = answered;
          _loading = false;
        });
        if (!_answeredToday) _showCheckInModal();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _streakData = StreakData(currentStreak: 0, streakStartDate: null, streakDates: []);
          _stats = const AppStats(daysAlcoholFree: 0, bestStreak: 0, checkInsCompleted: 0, currentRunStarted: null);
          _insightsResult = const InsightsResult(hasSufficientData: false);
          _answeredToday = false;
          _loading = false;
        });
        _showCheckInModal();
      }
    }
  }

  void _showCheckInModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckInModal(
        onYes: () async {
          await _repo.recordTodayAnswer(true);
          if (mounted) _load();
        },
        onNotToday: () async {
          await _repo.recordTodayAnswer(false);
          if (mounted) _load();
        },
        onSaveExtra: (difficulty, note) {
          _repo.setTodayCheckInExtra(difficulty, note);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clarity'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  StreakCard(streak: _streakData?.currentStreak ?? 0),
                  if (_streakData != null && _streakData!.streakDates.isNotEmpty)
                    StreakStrip(
                      streakDates: _streakData!.streakDates,
                      soberDatesSet: _streakData!.streakDates.toSet(),
                    ),
                  if (_stats != null) StatisticsCard(stats: _stats!),
                  if (_insightsResult != null) InsightsCard(result: _insightsResult!),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
