import 'package:flutter_test/flutter_test.dart';
import 'package:paz_mobile/features/main_shell.dart';
import 'package:paz_mobile/main.dart';

void main() {
  testWidgets('MainShell renders all 5 navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const PazApp(
        initialScreen: MainShell(),
      ),
    );

    expect(find.text('Markets'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Ask PAZ'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
