import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/fitness_data.dart';
import '../theme.dart';
import 'glass_card.dart';

/// Contribution-style heatmap of daily active minutes. Cells ripple in
/// diagonally; tap any cell to see that day.
class StreakHeatmapCard extends StatefulWidget {
  const StreakHeatmapCard({super.key});

  @override
  State<StreakHeatmapCard> createState() => _StreakHeatmapCardState();
}

class _StreakHeatmapCardState extends State<StreakHeatmapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  int _selected = FitnessData.todayIndex;

  static const _gap = 4.0;
  static const _labelWidth = 22.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cells are ~12dp, below the 48dp touch minimum, so instead of requiring a
  /// precise tap we snap to the nearest cell and let the finger scrub
  /// horizontally across the grid, ticking a haptic on each new day.
  void _selectAt(Offset local, double cell) {
    final col = (local.dx / (cell + _gap)).floor().clamp(
      0,
      FitnessData.heatmapWeeks - 1,
    );
    final row = (local.dy / (cell + _gap)).floor().clamp(0, 6);
    var index = col * 7 + row;
    // Snap future days back to today.
    if (FitnessData.heatmapMinutes[index] < 0) index = FitnessData.todayIndex;
    if (index == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final streak = FitnessData.currentStreak;
    final minutes = FitnessData.heatmapMinutes;
    final date = FitnessData.dateForCell(_selected);
    final selectedMinutes = minutes[_selected];
    final caption =
        '${weekdayShort[date.weekday - 1]}, ${monthShort[date.month - 1]} ${date.day}'
        '  ·  ${selectedMinutes == 0 ? 'Rest day' : '$selectedMinutes active min'}';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.streak,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                '$streak-day streak',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text('Last 20 weeks', style: AppText.label),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const cols = FitnessData.heatmapWeeks;
              final gridWidth = constraints.maxWidth - _labelWidth;
              final cell = (gridWidth - _gap * (cols - 1)) / cols;
              final gridHeight = cell * 7 + _gap * 6;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _labelWidth,
                    height: gridHeight,
                    child: Stack(
                      children: [
                        for (final (row, label) in const [
                          (0, 'M'),
                          (2, 'W'),
                          (4, 'F'),
                          (6, 'S'),
                        ])
                          Positioned(
                            top: row * (cell + _gap),
                            height: cell,
                            left: 0,
                            child: Center(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Semantics(
                    label:
                        '$streak day streak. Activity heatmap for the last '
                        '20 weeks. Selected: $caption',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _selectAt(d.localPosition, cell),
                      onHorizontalDragStart: (d) =>
                          _selectAt(d.localPosition, cell),
                      onHorizontalDragUpdate: (d) =>
                          _selectAt(d.localPosition, cell),
                      child: SizedBox(
                        width: gridWidth,
                        height: gridHeight,
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) => CustomPaint(
                              painter: _HeatmapPainter(
                                minutes: minutes,
                                cell: cell,
                                gap: _gap,
                                progress: _controller.value,
                                selected: _selected,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: motion(context, AppMotion.select),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    caption,
                    key: ValueKey(_selected),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const _Legend(),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.textSecondary, fontSize: 11);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Less', style: style),
        const SizedBox(width: 4),
        for (var level = 0; level <= 4; level++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: _HeatmapPainter.colorFor(level),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        const SizedBox(width: 4),
        const Text('More', style: style),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.minutes,
    required this.cell,
    required this.gap,
    required this.progress,
    required this.selected,
  });

  final List<int> minutes;
  final double cell;
  final double gap;
  final double progress;
  final int selected;

  static Color colorFor(int level) => switch (level) {
    0 => Colors.white.withValues(alpha: 0.06),
    1 => AppColors.exercise.withValues(alpha: 0.25),
    2 => AppColors.exercise.withValues(alpha: 0.5),
    3 => AppColors.exercise.withValues(alpha: 0.75),
    _ => AppColors.exercise,
  };

  @override
  void paint(Canvas canvas, Size size) {
    const cols = FitnessData.heatmapWeeks;
    final radius = Radius.circular(cell * 0.28);
    final paint = Paint();

    for (var i = 0; i < minutes.length; i++) {
      if (minutes[i] < 0) continue;
      final col = i ~/ 7;
      final row = i % 7;

      // Diagonal ripple: each cell starts a little after its top-left
      // neighbour.
      final delay = (col + row * 0.7) / (cols + 7 * 0.7) * 0.6;
      final local = Curves.easeOutBack.transform(
        ((progress - delay) / 0.4).clamp(0.0, 1.0),
      );
      if (local <= 0) continue;

      final rect = Rect.fromLTWH(
        col * (cell + gap),
        row * (cell + gap),
        cell,
        cell,
      );
      final scaled = Rect.fromCenter(
        center: rect.center,
        width: cell * local,
        height: cell * local,
      );
      paint.color = colorFor(FitnessData.levelFor(minutes[i]));
      canvas.drawRRect(RRect.fromRectAndRadius(scaled, radius), paint);
    }

    final col = selected ~/ 7;
    final row = selected % 7;
    final rect = Rect.fromLTWH(
      col * (cell + gap),
      row * (cell + gap),
      cell,
      cell,
    ).inflate(1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius + const Radius.circular(1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: math.min(progress * 2, 1)),
    );
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.progress != progress || old.selected != selected || old.cell != cell;
}
