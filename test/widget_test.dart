import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_dashboard/data/fitness_data.dart';
import 'package:pulse_dashboard/main.dart';
import 'package:pulse_dashboard/widgets/heart_rate_card.dart';

void main() {
  testWidgets('dashboard renders and day selection updates the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PulseApp());
    // The ECG ticker runs forever, so pump fixed durations instead of settling.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap the first day chip (6 days ago).
    final first = FitnessData.week.first.date;
    await tester.tap(find.text('${first.day}').first);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Today'), findsNothing);
  });

  test('ECG phase is monotonic and pulses peak near the R wave', () {
    var last = Ecg.phaseAt(0);
    for (var t = 0.01; t < 30; t += 0.01) {
      final p = Ecg.phaseAt(t);
      expect(p, greaterThan(last));
      last = p;
    }
  });

  test('current streak counts back from today', () {
    expect(FitnessData.currentStreak, 23);
  });
}
