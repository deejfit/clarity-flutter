import 'package:flutter/material.dart';

/// Format yyyy-MM-dd as "Jan 3" or "Jan 3 '24" if not current year.
String formatStreakDayLabel(String yyyyMMdd, int currentYear) {
  final p = yyyyMMdd.split('-');
  final year = int.parse(p[0]);
  final month = int.parse(p[1]);
  final day = int.parse(p[2]);
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final s = '${months[month - 1]} $day';
  if (year != currentYear) return '$s \'${year % 100}';
  return s;
}

/// Horizontal scrollable strip: days from streak start to today. No future days.
class StreakStrip extends StatefulWidget {
  const StreakStrip({
    super.key,
    required this.streakDates,
    required this.soberDatesSet,
  });

  /// Ordered list from first day of streak to today (yyyy-MM-dd).
  final List<String> streakDates;
  /// Set of dates that are marked sober (for completion indicator).
  final Set<String> soberDatesSet;

  @override
  State<StreakStrip> createState() => _StreakStripState();
}

class _StreakStripState extends State<StreakStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant StreakStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streakDates != widget.streakDates) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.streakDates;
    final set = widget.soberDatesSet;
    final currentYear = DateTime.now().year;

    if (dates.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 88,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final completed = set.contains(date);
          final dayNumber = index + 1;
          final label = formatStreakDayLabel(date, currentYear);
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 88,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: completed
                          ? Icon(
                              Icons.check,
                              size: 22,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
