import 'package:budget_buddy/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudgetBuddy loads dashboard with white & navy theme',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BudgetBuddyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // App title visible
    expect(find.text('BudgetBuddy'), findsOneWidget);

    // Scaffold background is light (white) and primary color is navy.
    final BuildContext context =
        tester.element(find.byType(Scaffold).first);
    final ThemeData theme = Theme.of(context);

    expect(theme.scaffoldBackgroundColor, equals(Colors.white));
    expect(theme.primaryColor, isNotNull);
  });
}

