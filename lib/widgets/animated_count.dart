import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// A number that counts up to [value], and tweens smoothly whenever
/// [value] changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.format,
    this.duration = const Duration(milliseconds: 900),
  });

  final num value;
  final TextStyle style;
  final String Function(double v)? format;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: motion(context, duration),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        format?.call(v) ?? groupDigits(v),
        style: style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
