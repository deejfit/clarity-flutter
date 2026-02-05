import 'package:flutter/material.dart';
import '../../models/app_stats.dart';

class StatisticsCard extends StatelessWidget {
  const StatisticsCard({super.key, required this.stats});

  final AppStats stats;

  static String _formatRunStarted(String yyyyMMdd) {
    final p = yyyyMMdd.split('-');
    final year = int.parse(p[0]);
    final month = int.parse(p[1]);
    final day = int.parse(p[2]);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $day, $year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Days alcohol-free',
              value: '${stats.daysAlcoholFree}',
              theme: theme,
            ),
            _StatRow(
              label: 'Best streak',
              value: '${stats.bestStreak} ${stats.bestStreak == 1 ? 'day' : 'days'}',
              theme: theme,
            ),
            _StatRow(
              label: 'Check-ins completed',
              value: '${stats.checkInsCompleted}',
              theme: theme,
            ),
            _StatRow(
              label: 'Current run started',
              value: stats.currentRunStarted != null
                  ? _formatRunStarted(stats.currentRunStarted!)
                  : '—',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
