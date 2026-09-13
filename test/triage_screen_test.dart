import 'package:carelink_mobile/screens/triage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TriageScreen displays disclaimer and basic questions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TriageScreen(),
      ),
    );

    // Verify mandatory disclaimer
    expect(
      find.text('AI-assisted preliminary triage, not a medical diagnosis.'),
      findsOneWidget,
    );

    // Verify main questions
    expect(
      find.text('1. What is the main problem or symptom?'),
      findsOneWidget,
    );
    expect(
      find.text('2. How long has it been happening?'),
      findsOneWidget,
    );
    expect(
      find.text('3. Can you walk and talk normally?'),
      findsOneWidget,
    );
    expect(
      find.text('4. Check all symptoms that apply:'),
      findsOneWidget,
    );
    expect(find.text('CHECK SYMPTOMS'), findsOneWidget);
  });

  testWidgets(
      'TriageScreen detects RED Emergency and invokes onEmergencyTriggered callback',
      (WidgetTester tester) async {
    bool emergencyTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TriageScreen(
          onEmergencyTriggered: (context) {
            emergencyTriggered = true;
          },
        ),
      ),
    );

    // Select breathing trouble chip
    final breathingChip = find.text('Breathing Trouble');
    expect(breathingChip, findsOneWidget);
    await tester.tap(breathingChip);
    await tester.pump();

    // Select unable to walk or talk
    final unableOption = find.text('No, unable to walk or talk');
    await tester.ensureVisible(unableOption);
    await tester.tap(unableOption);
    await tester.pump();

    // Tap Check Symptoms button
    final checkButton = find.text('CHECK SYMPTOMS');
    await tester.ensureVisible(checkButton);
    await tester.tap(checkButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify RED Emergency is displayed
    expect(find.text('URGENCY LEVEL: RED'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('TRIGGER EMERGENCY AUTOPILOT'), findsOneWidget);

    // Tap the emergency trigger button
    final triggerButton = find.text('TRIGGER EMERGENCY AUTOPILOT');
    await tester.ensureVisible(triggerButton);
    await tester.tap(triggerButton);
    await tester.pump();

    expect(emergencyTriggered, isTrue);
  });
}
