import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'animated_count.dart';
import 'glass_card.dart';

/// Compact metric card: icon, count-up value, and an optional goal bar.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.unit,
    this.goal,
    this.footnote,
    this.format,
  });

  final IconData icon;
  final Color color;
  final String label;
  final num value;
  final String? unit;
  final num? goal;
  final String? footnote;
  final String Function(double v)? format;

  @override
  Widget build(BuildContext context) {
    final fraction = goal == null ? null : (value / goal!).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedCount(
                    value: value,
                    format: format,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (fraction != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: color.withValues(alpha: 0.15)),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction.toDouble()),
                      duration: motion(
                        context,
                        const Duration(milliseconds: 900),
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, f, _) => FractionallySizedBox(
                        widthFactor: f,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 6), // keeps captions aligned across tiles
          // Progress is also stated in text, so it doesn't rely on colour.
          if (fraction != null || footnote != null) ...[
            const SizedBox(height: 8),
            Text(
              footnote ?? '${(value / goal! * 100).round()}% of goal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption,
            ),
          ],
        ],
      ),
    );
  }
}
