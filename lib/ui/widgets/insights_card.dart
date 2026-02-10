import 'package:flutter/material.dart';
import '../../logic/insights_service.dart';

/// Insights card: shows "not enough data" message or insight text + streak difficulty graph.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.result});

  final InsightsResult result;

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
              'Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (!result.hasSufficientData) _InsufficientDataContent(),
            if (result.hasSufficientData) ...[
              if (result.insightTexts.isNotEmpty) ...[
                ...result.insightTexts.map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (result.streakLength > 0 && result.streakDifficultyPoints.isNotEmpty)
                _StreakDifficultyGraph(
                  points: result.streakDifficultyPoints,
                  streakLength: result.streakLength,
                  color: theme.colorScheme.primary,
                  onSurfaceVariant: theme.colorScheme.onSurfaceVariant,
                )
              else if (result.streakLength > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No difficulty data for this streak yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsufficientDataContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not enough data yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Check in for a few more days to see patterns emerge.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Minimal line graph: X = day index (1..streakLength), Y = difficulty (1–5).
/// Only plots points with data; does not interpolate. Subtly highlights last point (today).
class _StreakDifficultyGraph extends StatelessWidget {
  const _StreakDifficultyGraph({
    required this.points,
    required this.streakLength,
    required this.color,
    required this.onSurfaceVariant,
  });

  final List<StreakDifficultyPoint> points;
  final int streakLength;
  final Color color;
  final Color onSurfaceVariant;

  static const double _yAxisWidth = 20;
  static const double _xAxisHeight = 24;
  static const double _chartPadding = 8;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current streak difficulty',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const pad = _chartPadding;
              final chartWidth = constraints.maxWidth - _yAxisWidth - pad * 2;
              final chartHeight = constraints.maxHeight - _xAxisHeight - pad * 2;
              if (chartWidth <= 0 || chartHeight <= 0) return const SizedBox.shrink();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _yAxisWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5', style: TextStyle(fontSize: 10, color: onSurfaceVariant)),
                        Text('1', style: TextStyle(fontSize: 10, color: onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      size: Size(chartWidth, chartHeight + pad * 2),
                      painter: _StreakDifficultyPainter(
                        points: points,
                        streakLength: streakLength,
                        color: color,
                        todayColor: color.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: _yAxisWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day 1', style: TextStyle(fontSize: 10, color: onSurfaceVariant)),
              if (streakLength > 1)
                Text('Today', style: TextStyle(fontSize: 10, color: onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakDifficultyPainter extends CustomPainter {
  _StreakDifficultyPainter({
    required this.points,
    required this.streakLength,
    required this.color,
    required this.todayColor,
  });

  final List<StreakDifficultyPoint> points;
  final int streakLength;
  final Color color;
  final Color todayColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final w = size.width;
    final h = size.height;
    const padding = 8.0;
    final chartLeft = padding;
    final chartRight = w - padding;
    final chartTop = padding;
    final chartBottom = h - padding;
    final chartW = chartRight - chartLeft;
    final chartH = chartBottom - chartTop;

    double xForDay(int dayIndex) {
      if (streakLength <= 1) return chartLeft + chartW / 2;
      return chartLeft + chartW * (dayIndex - 1) / (streakLength - 1);
    }

    // Y: 1 = bottom, 5 = top
    double yForDifficulty(int d) {
      return chartBottom - chartH * (d - 1) / 4;
    }

    final sortedPoints = List<StreakDifficultyPoint>.from(points)
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

    final path = Path();
    final first = sortedPoints.first;
    path.moveTo(xForDay(first.dayIndex), yForDifficulty(first.difficulty));

    for (var i = 1; i < sortedPoints.length; i++) {
      final p = sortedPoints[i];
      path.lineTo(xForDay(p.dayIndex), yForDifficulty(p.difficulty));
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    const dotRadius = 3.0;
    final dotPaint = Paint()..color = color;
    final todayPaint = Paint()..color = todayColor;

    final todayRingPaint = Paint()
      ..color = todayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < sortedPoints.length; i++) {
      final p = sortedPoints[i];
      final isToday = p.dayIndex == streakLength;
      final cx = xForDay(p.dayIndex);
      final cy = yForDifficulty(p.difficulty);
      canvas.drawCircle(Offset(cx, cy), dotRadius, isToday ? todayPaint : dotPaint);
      if (isToday) {
        canvas.drawCircle(Offset(cx, cy), dotRadius + 1.5, todayRingPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StreakDifficultyPainter old) {
    return old.streakLength != streakLength || old.points.length != points.length;
  }
}
