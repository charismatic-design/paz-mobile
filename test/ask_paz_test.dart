import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paz_mobile/core/theme/paz_theme.dart';
import 'package:paz_mobile/features/ask_paz/ask_paz_screen.dart';

void main() {
  testWidgets('AskPazScreen renders welcome state and starter prompt chips when empty', (WidgetTester tester) async {
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

    // Verify title, status and starter chips in welcome state
    expect(find.text('ASK PAZ'), findsOneWidget);
    expect(find.text('PAZ FINANCIAL AGENT READY'), findsOneWidget);
    expect(find.text('RECOMMENDED INQUIRIES'), findsOneWidget);
    expect(find.text('Best bank for \$1,000 today'), findsOneWidget);

    // Verify input area
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);

    await tester.enterText(inputFinder, 'What is the USD/ETB rate?');
    await tester.pump();
    expect(find.text('What is the USD/ETB rate?'), findsOneWidget);
  });

  testWidgets('AskPazScreen renders Markdown properly in AI bubbles', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final messages = [
      ChatMessage(
        text: 'What is today\'s market overview?',
        isUser: true,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: '### Portfolio Telemetry Updated\n\n'
            '**Top Commercial Bank (USD)**: **Bank of Abyssinia** at **162.70 ETB**.\n\n'
            '- 24K Gold: 11,840 ETB/g\n'
            '- CBE Spread: 2.1%\n\n'
            'Current policy rate is `15.0%`.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: AskPazScreen(initialMessages: messages),
      ),
    );
    await tester.pumpAndSettle();

    // Verify MarkdownBody is rendered for AI message
    expect(find.byType(MarkdownBody), findsOneWidget);

    // Welcome state chips should NOT be shown
    expect(find.text('RECOMMENDED INQUIRIES'), findsNothing);

    // Raw markdown tokens like "###" should NOT be present in raw text finding
    expect(find.textContaining('###'), findsNothing);

    // Rendered text content should be found inside the MarkdownBody
    expect(find.textContaining('Portfolio Telemetry Updated'), findsOneWidget);
    expect(find.textContaining('Bank of Abyssinia'), findsOneWidget);
    expect(find.textContaining('24K Gold: 11,840 ETB/g'), findsOneWidget);
  });

  testWidgets('Follow-up suggestions are only shown on the latest AI message with dynamic suggestions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final messagesWithDynamic = [
      ChatMessage(
        text: 'Compare bank spreads',
        isUser: true,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: 'Bank of Abyssinia offers the highest buying rate for USD today.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: ['Compare with Awash Bank spread', 'View gold karat breakdown'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: AskPazScreen(initialMessages: messagesWithDynamic),
      ),
    );
    await tester.pumpAndSettle();

    // Latest AI message displays dynamic suggestions
    expect(find.text('FOLLOW-UP SUGGESTIONS'), findsOneWidget);
    expect(find.text('Compare with Awash Bank spread'), findsOneWidget);
    expect(find.text('View gold karat breakdown'), findsOneWidget);
  });

  testWidgets('Follow-up suggestions are suppressed on older AI messages when a new message exists', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final multiTurnMessages = [
      ChatMessage(
        text: 'First question',
        isUser: true,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: 'First answer with old suggestions',
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: ['Old dynamic suggestion A', 'Old dynamic suggestion B'],
      ),
      ChatMessage(
        text: 'Second follow-up question',
        isUser: true,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: 'Second answer with empty suggestions',
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: const [],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: AskPazScreen(initialMessages: multiTurnMessages),
      ),
    );
    await tester.pumpAndSettle();

    // Since latest AI message has no suggestions, and older AI message is not latest:
    expect(find.text('FOLLOW-UP SUGGESTIONS'), findsNothing);
    expect(find.text('Old dynamic suggestion A'), findsNothing);
    expect(find.text('Old dynamic suggestion B'), findsNothing);
  });
}
