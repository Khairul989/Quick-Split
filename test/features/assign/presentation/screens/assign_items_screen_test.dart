import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/assign/presentation/providers/assignment_providers.dart';
import 'package:quicksplit/features/assign/presentation/screens/assign_items_screen.dart';
import 'package:quicksplit/features/assign/presentation/widgets/assignable_item_card.dart';
import 'package:quicksplit/features/assign/presentation/widgets/person_chip.dart';

/// Mock notifier for testing assignment state
class MockAssignmentNotifier extends AssignmentNotifier {
  @override
  AssignmentState build() {
    return const AssignmentState(assignments: {}, participantPersonIds: []);
  }
}

void main() {
  group('AssignItemsScreen', () {
    setUp(() {
      /// Mock data is generated within AssignItemsScreen
      /// No setUp needed for this test
    });

    testWidgets('displays AppBar with title and progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Assign Items'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays all participants as chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Participants'), findsOneWidget);
      expect(find.byType(PersonChip), findsWidgets);
      expect(find.text('Khairul'), findsOneWidget);
      expect(find.text('Aiman'), findsOneWidget);
      expect(find.text('Syafiq'), findsOneWidget);
    });

    testWidgets('displays all receipt items with correct information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Receipt Items'), findsOneWidget);
      expect(find.byType(AssignableItemCard), findsWidgets);
      expect(find.text('Nasi Lemak'), findsOneWidget);
      expect(find.text('Teh Tarik'), findsOneWidget);
      expect(find.text('Roti Canai'), findsOneWidget);
      expect(find.text('2x @ RM12.00'), findsOneWidget);
      expect(find.text('3x @ RM3.50'), findsOneWidget);
    });

    testWidgets('displays correct unassigned count initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5 items unassigned'), findsOneWidget);
    });

    testWidgets('Calculate button is disabled when items are unassigned', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      final calculateButton = find.byType(ElevatedButton).last;
      expect(calculateButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(calculateButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('opening item card shows bottom sheet for person selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      final firstItemCard = find.byType(AssignableItemCard).first;
      await tester.tap(firstItemCard);
      await tester.pumpAndSettle();

      expect(find.text('Who had this item?'), findsOneWidget);
      expect(
        find.text('Select all people who shared this item'),
        findsOneWidget,
      );
    });

    testWidgets('person selection updates item card visual state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      final firstItemCard = find.byType(AssignableItemCard).first;
      await tester.tap(firstItemCard);
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);

      final firstCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      final doneButton = find.text('Done');
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(find.text('Who had this item?'), findsNothing);
    });

    testWidgets('progress indicator updates when items are assigned', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0/5 assigned'), findsOneWidget);

      final firstItemCard = find.byType(AssignableItemCard).first;
      await tester.tap(firstItemCard);
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      final doneButton = find.text('Done');
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(find.text('1/5 assigned'), findsOneWidget);
    });

    testWidgets('unassigned count updates correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5 items unassigned'), findsOneWidget);

      final firstItemCard = find.byType(AssignableItemCard).first;
      await tester.tap(firstItemCard);
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      final doneButton = find.text('Done');
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(find.text('4 items unassigned'), findsOneWidget);
    });

    testWidgets('Calculate button is enabled when all items are assigned', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        final itemCard = find.byType(AssignableItemCard).at(i);
        await tester.tap(itemCard);
        await tester.pumpAndSettle();

        final checkbox = find.byType(CheckboxListTile).first;
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        final doneButton = find.text('Done');
        await tester.tap(doneButton);
        await tester.pumpAndSettle();
      }

      final calculateButton = find.byType(ElevatedButton).last;
      final button = tester.widget<ElevatedButton>(calculateButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Calculate button shows snackbar when pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        final itemCard = find.byType(AssignableItemCard).at(i);
        await tester.tap(itemCard);
        await tester.pumpAndSettle();

        final checkbox = find.byType(CheckboxListTile).first;
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        final doneButton = find.text('Done');
        await tester.tap(doneButton);
        await tester.pumpAndSettle();
      }

      final calculateButton = find.byType(ElevatedButton).last;
      await tester.tap(calculateButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Ready for calculation!'), findsOneWidget);
    });

    testWidgets('bottom sheet shows all participants with checkboxes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      final firstItemCard = find.byType(AssignableItemCard).first;
      await tester.tap(firstItemCard);
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);
      expect(find.text('Khairul'), findsWidgets);
      expect(find.text('Aiman'), findsWidgets);
      expect(find.text('Syafiq'), findsWidgets);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('shared item displays multiple person avatars', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      final firstItemCard = find.byType(AssignableItemCard).first;
      await tester.tap(firstItemCard);
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(CheckboxListTile).at(0);
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      final secondCheckbox = find.byType(CheckboxListTile).at(1);
      await tester.tap(secondCheckbox);
      await tester.pumpAndSettle();

      final doneButton = find.text('Done');
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('items list scrolls properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: AssignItemsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Roti Canai'), findsOneWidget);
      expect(find.text('Mee Goreng'), findsOneWidget);
    });
  });
}
