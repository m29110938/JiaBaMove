import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/features/profile/presentation/widgets/ruler_picker_widget.dart';

void main() {
  group('RulerPickerWidget & Unit Conversion Tests (CI/CD-First)', () {
    testWidgets('RulerPickerWidget renders horizontal decade numbers and centers properly',
        (tester) async {
      double pickedValue = 170.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 240,
                child: RulerPickerWidget(
                  minValue: 120,
                  maxValue: 230,
                  initialValue: 170,
                  unit: 'cm',
                  onValueChanged: (val) {
                    pickedValue = val;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the top indicator displays 170 cm and ruler contains decade mark 170
      expect(find.text('170'), findsNWidgets(2));
      expect(find.text('cm'), findsOneWidget);
      expect(pickedValue, equals(170.0));
    });

    testWidgets('RulerPickerWidget updates when unit and ranges switch',
        (tester) async {
      double heightValue = 170.0;
      String unit = 'cm';
      double minVal = 120.0;
      double maxVal = 230.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          unit = 'in';
                          minVal = 48.0;
                          maxVal = 90.0;
                          heightValue = 66.9; // 170 / 2.54
                        });
                      },
                      child: const Text('Switch to in'),
                    ),
                    RulerPickerWidget(
                      key: ValueKey(unit),
                      minValue: minVal,
                      maxValue: maxVal,
                      initialValue: heightValue,
                      unit: unit,
                      onValueChanged: (val) {},
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('cm'), findsOneWidget);

      // Tap unit switch
      await tester.tap(find.text('Switch to in'));
      await tester.pumpAndSettle();

      // Now it displays 'in'
      expect(find.text('in'), findsOneWidget);
      expect(find.text('66.9'), findsOneWidget);
    });
  });
}
