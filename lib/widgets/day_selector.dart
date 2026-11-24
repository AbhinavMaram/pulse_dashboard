import 'package:material_ui/material_ui.dart';

import '../data/fitness_data.dart';
import '../theme.dart';
import 'activity_rings.dart';
import 'pressable.dart';

List<RingSpec> ringsFor(DayActivity d) => [
  RingSpec(
    progress: d.moveProgress,
    start: AppColors.move,
    end: AppColors.moveEnd,
  ),
  RingSpec(
    progress: d.exerciseProgress,
    start: AppColors.exercise,
    end: AppColors.exerciseEnd,
  ),
  RingSpec(
    progress: d.standProgress,
    start: AppColors.stand,
    end: AppColors.standEnd,
  ),
];

/// A row of the last seven days, each with its own miniature rings.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.week,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DayActivity> week;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Each chip gets an equal column, so the hit area spans the full width
    // (>= 48dp on a 375pt phone) even though the visible pill is narrower.
    return Row(
      children: [
        for (var i = 0; i < week.length; i++)
          Expanded(
            child: _DayChip(
              day: week[i],
              index: i,
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final DayActivity day;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = weekdayShort[day.date.weekday - 1];
    return Semantics(
      button: true,
      selected: selected,
      label: '${weekdayFull[day.date.weekday - 1]} ${day.date.day}',
      child: Pressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: motion(context, AppMotion.select),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Text(
                  weekday.substring(0, 1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ActivityRings(
                  rings: ringsFor(day),
                  size: 28,
                  strokeWidth: 3.6,
                  gap: 1.2,
                  glow: false,
                  duration: Duration(milliseconds: 900 + index * 70),
                ),
                const SizedBox(height: 5),
                Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
