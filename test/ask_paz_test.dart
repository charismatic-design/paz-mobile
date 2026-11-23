import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paz_mobile/core/theme/paz_theme.dart';
import 'package:paz_mobile/features/ask_paz/ask_paz_screen.dart';

void main() {
  testWidgets('AskPazScreen renders welcome state and message bubbles without decoration assertion', (WidgetTester tester) async {
    // Test on standard mobile iPhone portrait dimensions (390 x 844)
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: const AskPazScreen(),
      ),
    );

    // Verify title and welcome state
    expect(find.text('ASK PAZ'), findsOneWidget);
    expect(find.text('PAZ FINANCIAL AGENT READY'), findsOneWidget);

    // Find input field and enter text
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);

    await tester.enterText(inputFinder, 'What is the USD/ETB rate?');
    await tester.pump();

    // Verify text entered
    expect(find.text('What is the USD/ETB rate?'), findsOneWidget);
  });
}
