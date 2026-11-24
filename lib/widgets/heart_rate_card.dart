import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../data/fitness_data.dart';
import '../theme.dart';
import 'glass_card.dart';

/// Synthetic ECG signal. Everything is an analytic function of time, so the
/// trace scrolls perfectly smoothly at any frame rate.
abstract final class Ecg {
  static double bpmAt(double t) =>
      72 + 5 * math.sin(t * 0.35) + 2 * math.sin(t * 1.3);

  /// Number of beats since t = 0 (the integral of bpm / 60).
  static double phaseAt(double t) =>
      (72 * t - 5 * math.cos(t * 0.35) / 0.35 - 2 * math.cos(t * 1.3) / 1.3) /
      60;

  static double sample(double t) {
    final f = phaseAt(t) % 1.0;
    return _g(f, 0.10, 0.12, 0.03) + // P
        _g(f, 0.20, -0.12, 0.012) + // Q
        _g(f, 0.225, 1.0, 0.018) + // R
        _g(f, 0.25, -0.28, 0.014) + // S
        _g(f, 0.46, 0.26, 0.05); // T
  }

  /// 0..1 pulse that peaks with the R wave; drives the heart icon.
  static double pulse(double t) => _g(phaseAt(t) % 1.0, 0.235, 1, 0.04);

  static double _g(double f, double c, double a, double w) {
    final d = f - c;
    return a * math.exp(-(d * d) / (2 * w * w));
  }
}

class HeartRateCard extends StatefulWidget {
  const HeartRateCard({super.key, required this.day});

  final DayActivity day;

  @override
  State<HeartRateCard> createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<HeartRateCard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _time = ValueNotifier<double>(0);
  final _bpm = ValueNotifier<int>(72);
  int _lastBeat = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
      _time.value = 3.4; // a still frame with a few beats visible
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _time.value = t;
    // Like a real monitor, update the number once per beat.
    final beat = Ecg.phaseAt(t).floor();
    if (beat != _lastBeat) {
      _lastBeat = beat;
      _bpm.value = Ecg.bpmAt(t).round();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _bpm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _time,
                builder: (context, child) => Transform.scale(
                  scale: 1 + 0.22 * Ecg.pulse(_time.value),
                  child: child,
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.move.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.move,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Heart rate',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _bpm,
                    builder: (context, bpm, _) => Semantics(
                      liveRegion: false,
                      label: '$bpm beats per minute',
                      child: ExcludeSemantics(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$bpm',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: tabular,
                                  height: 1.1,
                                ),
                              ),
                              const TextSpan(
                                text: ' BPM',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
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
              const Spacer(),
              _LiveBadge(time: _time),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _EcgPainter(time: _time, color: AppColors.move),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(label: 'Resting', value: widget.day.restingHr),
              _MiniStat(label: 'Average', value: widget.day.avgHr),
              _MiniStat(label: 'Max', value: widget.day.maxHr),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.time});

  final ValueListenable<double> time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.move.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: time,
            builder: (context, child) => Opacity(
              opacity:
                  0.35 + 0.65 * (0.5 + 0.5 * math.cos(time.value * math.pi)),
              child: child,
            ),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.move,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.move,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: motion(context, const Duration(milliseconds: 700)),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${v.round()} bpm',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter({required this.time, required this.color}) : super(repaint: time);

  final ValueListenable<double> time;
  final Color color;

  static const _windowSeconds = 3.0;
  static const _headInset = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Monitor grid
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 0; i <= 12; i++) {
      final x = size.width * i / 12;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final t = time.value;
    final w = size.width - _headInset;
    final mid = size.height * 0.62;
    final amp = size.height * 0.55;
    double yAt(double st) => mid - Ecg.sample(st) * amp;

    final path = Path();
    for (var x = 0.0; x <= w; x += 1) {
      final y = yAt(t - _windowSeconds + x / w * _windowSeconds);
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    final fade = LinearGradient(
      colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.7), color],
      stops: const [0, 0.35, 1],
    ).createShader(Offset.zero & size);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..shader = fade
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = fade,
    );

    final head = Offset(w, yAt(t));
    canvas.drawCircle(
      head,
      9,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(head, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.color != color;
}
