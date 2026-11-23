import 'package:flutter_test/flutter_test.dart';
import 'package:paz_mobile/features/auth/login_screen.dart';
import 'package:paz_mobile/main.dart';

void main() {
  testWidgets('PAZ Terminal app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const PazApp(
        initialScreen: LoginScreen(),
      ),
    );

    expect(find.text('PAZ FINANCIAL'), findsOneWidget);
    expect(find.text('TERMINAL'), findsOneWidget);
    expect(find.text('Sign In & Enter Terminal'), findsOneWidget);
  });
}
