import 'dart:math' as math;

/// One day of activity. All numbers are mock data for the demo.
class DayActivity {
  const DayActivity({
    required this.date,
    required this.moveKcal,
    required this.exerciseMin,
    required this.standHours,
    required this.steps,
    required this.sleepMinutes,
    required this.restingHr,
    required this.avgHr,
    required this.maxHr,
  });

  static const moveGoal = 600;
  static const exerciseGoal = 30;
  static const standGoal = 12;
  static const stepGoal = 8000;
  static const sleepGoal = 480;
  static const distanceGoalKm = 6.0;

  final DateTime date;
  final int moveKcal;
  final int exerciseMin;
  final int standHours;
  final int steps;
  final int sleepMinutes;
  final int restingHr;
  final int avgHr;
  final int maxHr;

  double get distanceKm => steps * 0.00078;
  double get moveProgress => moveKcal / moveGoal;
  double get exerciseProgress => exerciseMin / exerciseGoal;
  double get standProgress => standHours / standGoal;
}

abstract final class FitnessData {
  static final DateTime today = _dateOnly(DateTime.now());

  /// The last seven days, oldest first; the last entry is today.
  static final List<DayActivity> week = _buildWeek();

  static const heatmapWeeks = 20;

  /// Active minutes per day for the heatmap, column-major (one column per
  /// week, Monday at the top). -1 marks days that haven't happened yet.
  static final List<int> heatmapMinutes = _buildHeatmap();

  /// Index of today inside [heatmapMinutes].
  static int get todayIndex => (heatmapWeeks - 1) * 7 + (today.weekday - 1);

  static DateTime dateForCell(int index) =>
      DateTime(today.year, today.month, today.day - (todayIndex - index));

  static int get currentStreak {
    var streak = 0;
    for (var i = todayIndex; i >= 0 && heatmapMinutes[i] > 0; i--) {
      streak++;
    }
    return streak;
  }

  static int levelFor(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes < 20) return 1;
    if (minutes < 35) return 2;
    if (minutes < 50) return 3;
    return 4;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<DayActivity> _buildWeek() {
    const move = [520, 645, 380, 710, 590, 820, 412];
    const exercise = [28, 42, 15, 55, 31, 64, 22];
    const stand = [10, 12, 8, 13, 11, 12, 7];
    const steps = [7420, 9810, 5230, 11240, 8560, 13105, 6140];
    const sleep = [412, 455, 388, 470, 501, 432, 444];
    const resting = [61, 59, 63, 58, 60, 57, 62];
    const avg = [74, 79, 71, 83, 76, 88, 73];
    const max = [138, 151, 122, 164, 142, 171, 129];
    return [
      for (var i = 0; i < 7; i++)
        DayActivity(
          date: DateTime(today.year, today.month, today.day - (6 - i)),
          moveKcal: move[i],
          exerciseMin: exercise[i],
          standHours: stand[i],
          steps: steps[i],
          sleepMinutes: sleep[i],
          restingHr: resting[i],
          avgHr: avg[i],
          maxHr: max[i],
        ),
    ];
  }

  static List<int> _buildHeatmap() {
    final rand = math.Random(42);
    final todayIdx = (heatmapWeeks - 1) * 7 + (today.weekday - 1);
    const streakLength = 23;
    return [
      for (var i = 0; i < heatmapWeeks * 7; i++)
        if (i > todayIdx)
          -1
        else if (i > todayIdx - 7)
          // Keep the last week consistent with the exercise ring data.
          week[6 - (todayIdx - i)].exerciseMin
        else if (i > todayIdx - streakLength)
          10 + rand.nextInt(60)
        else if (i == todayIdx - streakLength)
          0 // the day the streak started after
        else
          rand.nextDouble() < 0.24 ? 0 : 8 + rand.nextInt(68),
    ];
  }
}
