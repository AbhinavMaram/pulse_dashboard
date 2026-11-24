import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class RingSpec {
  const RingSpec({
    required this.progress,
    required this.start,
    required this.end,
  });

  /// 1.0 = goal reached. Values above 1 draw extra laps.
  final double progress;
  final Color start;
  final Color end;
}

/// Concentric progress rings drawn with [CustomPainter].
///
/// * Each ring sweeps with a gradient and staggered easing.
/// * Progress above 100% keeps going round, with a shadow under the tip so the
///   overlap reads as depth.
/// * When [rings] change the rings tween from their current position, so
///   switching days feels continuous.
class ActivityRings extends StatefulWidget {
  const ActivityRings({
    super.key,
    required this.rings,
    this.size = 180,
    this.strokeWidth = 18,
    this.gap = 4,
    this.glow = true,
    this.replayOnTap = false,
    this.semanticsLabel,
    this.replayToken = 0,
    this.duration = const Duration(milliseconds: 1400),
  });

  /// Change this value to replay the fill animation from zero.
  final int replayToken;

  final List<RingSpec> rings;
  final double size;
  final double strokeWidth;
  final double gap;
  final bool glow;
  final bool replayOnTap;
  final String? semanticsLabel;
  final Duration duration;

  @override
  State<ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<double> _from;
  late List<double> _to;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _from = List.filled(widget.rings.length, 0);
    _to = [for (final r in widget.rings) r.progress];
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant ActivityRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replayToken != oldWidget.replayToken) {
      _to = [for (final r in widget.rings) r.progress];
      _replay();
      return;
    }
    final next = [for (final r in widget.rings) r.progress];
    if (!listEquals(next, _to)) {
      _from = next.length == _to.length
          ? _values()
          : List.filled(next.length, 0);
      _to = next;
      _restart();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _restart() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _replay() {
    _from = List.filled(_to.length, 0);
    _restart();
  }

  /// Current animated progress for every ring. Outer rings lead, inner rings
  /// follow slightly behind.
  List<double> _values() {
    return [
      for (var i = 0; i < _to.length; i++)
        lerpDouble(
          _from[i],
          _to[i],
          Interval(
            math.min(i * 0.1, 0.5),
            math.min(0.8 + i * 0.1, 1.0),
            curve: Curves.easeOutCubic,
          ).transform(_controller.value),
        )!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget child = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _RingsPainter(
            values: _values(),
            rings: widget.rings,
            strokeWidth: widget.strokeWidth,
            gap: widget.gap,
            glow: widget.glow,
          ),
        ),
      ),
    );
    if (widget.replayOnTap) {
      child = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _replay();
        },
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    return Semantics(
      label: widget.semanticsLabel,
      button: widget.replayOnTap,
      child: ExcludeSemantics(child: child),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.values,
    required this.rings,
    required this.strokeWidth,
    required this.gap,
    required this.glow,
  });

  final List<double> values;
  final List<RingSpec> rings;
  final double strokeWidth;
  final double gap;
  final bool glow;

  static const _top = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < rings.length; i++) {
      final radius =
          size.shortestSide / 2 - strokeWidth / 2 - i * (strokeWidth + gap);
      if (radius <= 0) continue;

      // Track
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = rings[i].start.withValues(alpha: 0.16),
      );

      final p = values[i];
      if (p > 0.001) _paintProgress(canvas, center, radius, rings[i], p);
    }
  }

  void _paintProgress(
    Canvas canvas,
    Offset center,
    double radius,
    RingSpec ring,
    double p,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final tipAngle = _top + 2 * math.pi * p;
    final capRadius = strokeWidth / 2;
    Offset pointAt(double angle) =>
        center + Offset(math.cos(angle), math.sin(angle)) * radius;

    if (glow) {
      canvas.drawArc(
        rect,
        _top,
        2 * math.pi * math.min(p, 1),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = ring.start.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (p <= 1) {
      // Gradient runs from the top to the tip.
      stroke.shader = SweepGradient(
        colors: [ring.start, ring.end],
        stops: [0, p],
        transform: const GradientRotation(_top),
      ).createShader(rect);
      canvas.drawArc(rect, _top, 2 * math.pi * p, false, stroke);
      canvas.drawCircle(pointAt(_top), capRadius, Paint()..color = ring.start);
    } else {
      // Over 100%: a full lap whose gradient ends exactly at the tip, so the
      // colour seam hides under the tip cap.
      stroke.shader = SweepGradient(
        colors: [ring.start, ring.end],
        transform: GradientRotation(tipAngle),
      ).createShader(rect);
      canvas.drawCircle(center, radius, stroke);

      // Shadow cast forward onto the previous lap.
      final tangent = Offset(-math.sin(tipAngle), math.cos(tipAngle));
      canvas.drawCircle(
        pointAt(tipAngle) + tangent * (capRadius * 0.35),
        capRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, capRadius * 0.45),
      );
    }

    canvas.drawCircle(pointAt(tipAngle), capRadius, Paint()..color = ring.end);
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      !listEquals(old.values, values) ||
      old.strokeWidth != strokeWidth ||
      old.gap != gap ||
      old.glow != glow;
}
