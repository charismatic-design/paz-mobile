import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paz_mobile/core/theme/paz_theme.dart';
import 'package:paz_mobile/features/account/account_subpages.dart';
import 'package:paz_mobile/features/portfolio/portfolio_screen.dart';
import 'package:paz_mobile/features/terminal/markets_screen.dart';
import 'package:paz_mobile/features/tools/tools_screen.dart';

void main() {
  testWidgets('MarketsScreen renders sub-tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: const MarketsScreen(),
      ),
    );

    expect(find.text('PAZ TERMINAL'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Bank FX'), findsOneWidget);
    expect(find.text('Gold 24K'), findsOneWidget);
  });

  testWidgets('ToolsScreen renders remittance and ESX tools', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: const ToolsScreen(),
      ),
    );

    expect(find.text('Remittance'), findsOneWidget);
    expect(find.text('ESX / Equities'), findsOneWidget);
    expect(find.text('DIASPORA REMITTANCE OPTIMIZER'), findsOneWidget);
  });

  testWidgets('PortfolioScreen renders in guest/authenticated mode', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: const PortfolioScreen(),
      ),
    );

    expect(find.text('PORTFOLIO & MONEY SYNC'), findsOneWidget);
  });

  testWidgets('Account sub-pages render properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: PazTheme.darkTheme,
        home: const AboutPazScreen(),
      ),
    );

    expect(find.text('ABOUT PAZ TERMINAL'), findsOneWidget);
    expect(find.text('DATA SOVEREIGNTY & SOURCES'), findsOneWidget);
  });
}
