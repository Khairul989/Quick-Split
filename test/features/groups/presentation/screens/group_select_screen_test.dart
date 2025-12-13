import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';
import 'package:quicksplit/features/groups/presentation/providers/group_providers.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_select_screen.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

/// Mock Receipt for testing
final mockReceipt = Receipt(items: [], subtotal: 0.0, total: 0.0);

/// Mock notifier for testing
class MockGroupsNotifier extends GroupsNotifier {
  final List<Group> _groups;
  final List<Person> _people;

  MockGroupsNotifier({
    required List<Group> groups,
    required List<Person> people,
  }) : _groups = groups,
       _people = people;

  @override
  GroupsState build() {
    return GroupsState(groups: _groups, people: _people);
  }
}

void main() {
  group('GroupSelectScreen', () {
    testWidgets('displays empty state when no groups exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GroupSelectScreen(receipt: mockReceipt)),
          ),
        ),
      );

      expect(find.text('No Groups Yet'), findsOneWidget);
      expect(
        find.text('Create a group to get started splitting bills'),
        findsOneWidget,
      );
      expect(find.text('Create Your First Group'), findsOneWidget);
    });

    testWidgets('displays all groups in vertical list', (
      WidgetTester tester,
    ) async {
      final person1 = Person(name: 'Alice', emoji: '👩');
      final person2 = Person(name: 'Bob', emoji: '👨');
      final group1 = Group(
        name: 'Weekend Trip',
        personIds: [person1.id, person2.id],
      );
      final group2 = Group(name: 'Lunch', personIds: [person1.id]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(
                groups: [group1, group2],
                people: [person1, person2],
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GroupSelectScreen(receipt: mockReceipt)),
          ),
        ),
      );

      expect(find.text('All Groups'), findsOneWidget);
      expect(find.text('Weekend Trip'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('displays frequent groups horizontal list', (
      WidgetTester tester,
    ) async {
      final person1 = Person(name: 'Alice', emoji: '👩');
      final person2 = Person(name: 'Bob', emoji: '👨');
      final group1 = Group(
        name: 'Weekend Trip',
        personIds: [person1.id, person2.id],
        lastUsedAt: DateTime.now(),
      );
      final group2 = Group(
        name: 'Lunch',
        personIds: [person1.id],
        lastUsedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(
                groups: [group1, group2],
                people: [person1, person2],
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GroupSelectScreen(receipt: mockReceipt)),
          ),
        ),
      );

      expect(find.text('Frequent Groups'), findsOneWidget);
      expect(find.text('Weekend Trip'), findsWidgets);
    });

    testWidgets('FAB is present for creating new group', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GroupSelectScreen(receipt: mockReceipt)),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows snackbar on group selection', (
      WidgetTester tester,
    ) async {
      final person1 = Person(name: 'Alice', emoji: '👩');
      final group1 = Group(name: 'Weekend Trip', personIds: [person1.id]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: [group1], people: [person1]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GroupSelectScreen(receipt: mockReceipt)),
          ),
        ),
      );

      await tester.tap(find.text('Weekend Trip').first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Selected: Weekend Trip'), findsOneWidget);
    });

    testWidgets('member count displays correctly', (WidgetTester tester) async {
      final person1 = Person(name: 'Alice', emoji: '👩');
      final person2 = Person(name: 'Bob', emoji: '👨');
      final group1 = Group(
        name: 'Test Group',
        personIds: [person1.id, person2.id],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(
                groups: [group1],
                people: [person1, person2],
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GroupSelectScreen(receipt: mockReceipt)),
          ),
        ),
      );

      expect(find.text('2 members'), findsOneWidget);
    });

    testWidgets('scrolls through groups list', (WidgetTester tester) async {
      final people = List.generate(
        5,
        (i) => Person(name: 'Person $i', emoji: '👤'),
      );
      final groups = List.generate(
        10,
        (i) => Group(name: 'Group $i', personIds: [people[i % 5].id]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: groups, people: people),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GroupSelectScreen(receipt: mockReceipt)),
          ),
        ),
      );

      expect(find.text('Group 0'), findsOneWidget);
      expect(find.text('Group 9'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Group 9'), findsOneWidget);
    });
  });
}
