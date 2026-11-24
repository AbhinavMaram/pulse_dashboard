import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/fitness_data.dart';
import '../theme.dart';
import '../widgets/activity_rings.dart';
import '../widgets/animated_count.dart';
import '../widgets/day_selector.dart';
import '../widgets/glass_card.dart';
import '../widgets/heart_rate_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/streak_heatmap_card.dart';
import '../widgets/weekly_steps_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _week = FitnessData.week;
  late int _selected = _week.length - 1;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.value == 0) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  int _generation = 0;

  void _select(int i) => setState(() => _selected = i);

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    // Simulate a short sync so the indicator reads as real work.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    final day = _week[_selected];
    final sections = <Widget>[
      _Header(day: day, isToday: _selected == _week.length - 1),
      DaySelector(week: _week, selectedIndex: _selected, onSelect: _select),
      _RingsCard(day: day),
      HeartRateCard(day: day),
      _StatsGrid(day: day),
      WeeklyStepsCard(week: _week, selectedIndex: _selected, onSelect: _select),
      const StreakHeatmapCard(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            bottom: false,
            // Pull down to refresh: re-keys every section so the rings,
            // counters, bars and heatmap all replay their entrance.
            child: RefreshIndicator(
              color: AppColors.exercise,
              backgroundColor: AppColors.surface,
              onRefresh: _refresh,
              child: ListView.separated(
                key: ValueKey(_generation),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: sections.length,
                separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 20 : 16),
                itemBuilder: (_, i) => _Entrance(
                  animation: _entrance,
                  index: i,
                  child: sections[i],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts a section into place, staggered by [index].
class _Entrance extends StatefulWidget {
  const _Entrance({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> {
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: widget.animation,
    curve: Interval(
      math.min(widget.index * 0.08, 0.55),
      math.min(widget.index * 0.08 + 0.45, 1.0),
      curve: Curves.easeOutCubic,
    ),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_curve);

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    Widget blob(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -100,
            child: blob(AppColors.exercise.withValues(alpha: 0.16), 360),
          ),
          Positioned(
            top: 380,
            right: -140,
            child: blob(AppColors.stand.withValues(alpha: 0.13), 380),
          ),
          Positioned(
            top: 900,
            left: -120,
            child: blob(AppColors.move.withValues(alpha: 0.12), 360),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.day, required this.isToday});

  final DayActivity day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final d = day.date;
    final dateLabel =
        '${weekdayFull[d.weekday - 1]}, ${monthShort[d.month - 1]} ${d.day}'
            .toUpperCase();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: motion(context, const Duration(milliseconds: 220)),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  isToday ? 'Today' : weekdayFull[d.weekday - 1],
                  key: ValueKey(d),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.exercise, AppColors.stand],
            ),
          ),
          child: const Text(
            'A',
            style: TextStyle(
              color: AppColors.bg,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingsCard extends StatefulWidget {
  const _RingsCard({required this.day});

  final DayActivity day;

  @override
  State<_RingsCard> createState() => _RingsCardState();
}

class _RingsCardState extends State<_RingsCard> {
  int _replayToken = 0;

  /// The most actionable next step: the open ring that's closest to done.
  static (IconData, String) _insight(DayActivity d) {
    final open = [
      (
        d.moveProgress,
        '${DayActivity.moveGoal - d.moveKcal} kcal to close Move',
      ),
      (
        d.exerciseProgress,
        '${DayActivity.exerciseGoal - d.exerciseMin} min to close Exercise',
      ),
      (
        d.standProgress,
        '${DayActivity.standGoal - d.standHours} more hours to close Stand',
      ),
    ].where((r) => r.$1 < 1).toList()..sort((a, b) => b.$1.compareTo(a.$1));
    if (open.isEmpty) {
      return (Icons.emoji_events_rounded, 'All three rings closed. Nice work!');
    }
    return (Icons.bolt_rounded, open.first.$2);
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final pct = [
      day.moveProgress,
      day.exerciseProgress,
      day.standProgress,
    ].map((p) => '${(p * 100).round()}%').toList();
    final (insightIcon, insightText) = _insight(day);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Activity', style: AppText.sectionTitle),
              ),
              IconButton(
                tooltip: 'Replay ring animation',
                color: AppColors.textSecondary,
                icon: const Icon(Icons.replay_rounded, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _replayToken++);
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ringsRow(day, pct),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: motion(context, AppMotion.select),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: Container(
                  key: ValueKey(insightText),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(insightIcon, size: 18, color: AppColors.streak),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insightText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ringsRow(DayActivity day, List<String> pct) {
    return Row(
      children: [
        ActivityRings(
          rings: ringsFor(day),
          size: 150,
          strokeWidth: 16,
          gap: 4,
          replayOnTap: true,
          replayToken: _replayToken,
          semanticsLabel:
              'Activity rings. Move ${pct[0]}, '
              'exercise ${pct[1]}, stand ${pct[2]}. Tap to replay.',
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RingLegend(
                label: 'Move',
                value: day.moveKcal,
                goal: DayActivity.moveGoal,
                unit: 'KCAL',
                color: AppColors.move,
              ),
              const SizedBox(height: 14),
              _RingLegend(
                label: 'Exercise',
                value: day.exerciseMin,
                goal: DayActivity.exerciseGoal,
                unit: 'MIN',
                color: AppColors.exercise,
              ),
              const SizedBox(height: 14),
              _RingLegend(
                label: 'Stand',
                value: day.standHours,
                goal: DayActivity.standGoal,
                unit: 'HRS',
                color: AppColors.stand,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedCount(
                value: value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '/$goal $unit',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.day});

  final DayActivity day;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: 12, height: 12);
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.exercise,
                  label: 'Steps',
                  value: day.steps,
                  goal: DayActivity.stepGoal,
                ),
              ),
              gap,
              Expanded(
                child: StatTile(
                  icon: Icons.route_rounded,
                  color: AppColors.stand,
                  label: 'Distance',
                  value: day.distanceKm,
                  unit: 'km',
                  goal: DayActivity.distanceGoalKm,
                  format: (v) => v.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ),
        gap,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.bedtime_rounded,
                  color: AppColors.sleep,
                  label: 'Sleep',
                  value: day.sleepMinutes,
                  goal: DayActivity.sleepGoal,
                  format: (v) => '${v ~/ 60}h ${(v % 60).round()}m',
                ),
              ),
              gap,
              Expanded(
                child: StatTile(
                  icon: Icons.monitor_heart_rounded,
                  color: AppColors.move,
                  label: 'Resting HR',
                  value: day.restingHr,
                  unit: 'bpm',
                  footnote: 'Normal range 60-100',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
