import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/assign/presentation/screens/summary_screen.dart';
import 'package:quicksplit/features/assign/presentation/widgets/person_share_card.dart';

void main() {
  group('SummaryScreen', () {
    testWidgets('displays AppBar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Split Summary'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays receipt information card', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Restoran Murni'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.textContaining('RM'), findsWidgets);
    });

    testWidgets('displays Individual Shares section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Individual Shares'), findsOneWidget);
    });

    testWidgets('renders PersonShareCard for each person', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PersonShareCard), findsWidgets);
      expect(find.text('Khairul'), findsOneWidget);
      expect(find.text('Aiman'), findsOneWidget);
    });

    testWidgets('displays action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Assignments'), findsOneWidget);
      expect(find.text('Copy Split'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('copy button shows snackbar when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.byType(ElevatedButton);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('displays SST value in receipt info', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SST'), findsOneWidget);
      expect(find.text('RM 2.07'), findsOneWidget);
    });

    testWidgets('displays service charge in receipt info', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Service Charge'), findsOneWidget);
      expect(find.text('RM 3.45'), findsOneWidget);
    });

    testWidgets('PersonShareCard expands to show breakdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the first PersonShareCard expansion tile
      final expansionTile = find.byType(ExpansionTile).first;
      expect(expansionTile, findsOneWidget);

      // Tap to expand
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      // Should show breakdown details
      expect(find.text('Items Subtotal'), findsWidgets);
    });

    testWidgets('displays emoji avatars for each person', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('😊'), findsOneWidget);
      expect(find.text('😎'), findsOneWidget);
    });

    testWidgets('scroll view contains all content', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SummaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });
}
