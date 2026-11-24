import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/fitness_data.dart';
import '../theme.dart';
import 'glass_card.dart';
import 'pressable.dart';

/// Seven bars that grow in with a stagger. Tapping a bar selects that day for
/// the whole dashboard.
class WeeklyStepsCard extends StatelessWidget {
  const WeeklyStepsCard({
    super.key,
    required this.week,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DayActivity> week;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _valueRow = 18.0;
  static const _labelRow = 18.0;
  static const _spacing = 4.0 + 6.0;

  @override
  Widget build(BuildContext context) {
    final avg = week.fold<int>(0, (s, d) => s + d.steps) / week.length;
    final peak = week.map((d) => d.steps).reduce(math.max);
    final maxValue = math.max(peak, DayActivity.stepGoal) * 1.08;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Steps this week', style: AppText.sectionTitle),
              const Spacer(),
              Text(
                'avg ${groupDigits(avg)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Goal legend lives in the header so it never collides with the
          // selected bar's value label.
          Row(
            children: [
              CustomPaint(
                size: const Size(14, 1),
                painter: _DashedLinePainter(),
              ),
              const SizedBox(width: 6),
              Text(
                'Goal ${groupDigits(DayActivity.stepGoal)} steps',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight =
                    constraints.maxHeight - _valueRow - _labelRow - _spacing;
                final goalTop =
                    _valueRow +
                    4 +
                    chartHeight * (1 - DayActivity.stepGoal / maxValue);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: goalTop,
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 1),
                        painter: _DashedLinePainter(),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < week.length; i++)
                          Expanded(
                            child: _Bar(
                              index: i,
                              day: week[i],
                              fraction: week[i].steps / maxValue,
                              chartHeight: chartHeight,
                              selected: i == selectedIndex,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.index,
    required this.day,
    required this.fraction,
    required this.chartHeight,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final DayActivity day;
  final double fraction;
  final double chartHeight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metGoal = day.steps >= DayActivity.stepGoal;
    const fast = AppMotion.select;
    final label = weekdayShort[day.date.weekday - 1];
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${groupDigits(day.steps)} steps',
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: WeeklyStepsCard._valueRow,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: motion(context, fast),
                  child: FittedBox(
                    // Opaque pill so the value stays legible where it
                    // crosses the dashed goal line.
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          groupDigits(day.steps),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: motion(
                  context,
                  Duration(milliseconds: 650 + index * 90),
                ),
                curve: Curves.easeOutCubic,
                builder: (context, f, _) => SizedBox(
                  width: 22,
                  height: math.max(chartHeight * f, 4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: metGoal ? 0.2 : 0.09,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: motion(context, fast),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.exercise,
                                AppColors.exerciseEnd,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.exercise.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: WeeklyStepsCard._labelRow,
                child: AnimatedDefaultTextStyle(
                  duration: motion(context, fast),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  child: Text(label.substring(0, 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}
