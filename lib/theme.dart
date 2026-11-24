import 'package:material_ui/material_ui.dart';

/// Colour tokens for the Pulse dashboard.
abstract final class AppColors {
  static const bg = Color(0xFF0A0C10);
  static const surface = Color(0xFF14171D);
  static const textPrimary = Color(0xFFF2F4F7);
  static const textSecondary = Color(0xFF8A93A3);

  // Ring palettes (start -> end of the sweep gradient).
  static const move = Color(0xFFFF3D6B);
  static const moveEnd = Color(0xFFFF8FAB);
  static const exercise = Color(0xFF9EF01A);
  static const exerciseEnd = Color(0xFFD8FF7A);
  static const stand = Color(0xFF2ED3F5);
  static const standEnd = Color(0xFF9BEFFF);

  static const sleep = Color(0xFF9B8CFF);
  static const streak = Color(0xFFFF9F1C);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.exercise,
      surface: AppColors.surface,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}

/// Shared timing tokens, so interactions feel consistent.
abstract final class AppMotion {
  /// Pressed-state feedback; must land within ~80-150ms.
  static const press = Duration(milliseconds: 110);

  /// Selection changes (chips, bars, captions).
  static const select = Duration(milliseconds: 240);
}

/// Shared text styles. Nothing that carries information goes below 12px.
abstract final class AppText {
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const label = TextStyle(color: AppColors.textSecondary, fontSize: 13);
  static const caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    height: 1.3,
  );
}

/// Returns [d], or zero when the OS asks for reduced motion.
Duration motion(BuildContext context, Duration d) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

/// 8432 -> "8,432"
String groupDigits(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayFull = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
