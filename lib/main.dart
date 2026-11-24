import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'screens/dashboard_screen.dart';
import 'theme.dart';

void main() => runApp(const PulseApp());

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse - Fitness Dashboard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Honour the user's font size, but cap it so dense dashboard tiles
      // stay legible instead of clipping.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: _DeviceFrame(child: child!),
      ),
      home: const DashboardScreen(),
    );
  }
}

/// On wide screens (web / desktop) show the app inside a phone-sized frame so
/// the portfolio demo reads as a mobile app.
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) return child;

    const width = 420.0;
    final height = math.min(size.height - 48, 900.0);
    return ColoredBox(
      color: const Color(0xFF05060A),
      child: Center(
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: AppColors.exercise.withValues(alpha: 0.08),
                blurRadius: 80,
                spreadRadius: 4,
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: const Color(0xFF2A2E36), width: 6),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(width, height),
              padding: const EdgeInsets.only(top: 18),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
