import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';
import 'package:quicksplit/features/groups/presentation/providers/group_providers.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_create_screen.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

/// Mock Receipt for testing
final mockReceipt = Receipt(
  items: [],
  subtotal: 0.0,
  total: 0.0,
);

/// Mock notifier for testing
class MockGroupsNotifier extends GroupsNotifier {
  final List<Group> _groups;
  final List<Person> _people;
  Group? _createdGroup;

  MockGroupsNotifier({
    required List<Group> groups,
    required List<Person> people,
  })  : _groups = groups,
        _people = people;

  @override
  GroupsState build() {
    return GroupsState(groups: _groups, people: _people);
  }

  @override
  Future<Group> createGroup(String name, List<Person> people) async {
    _createdGroup = Group(
      name: name,
      personIds: people.map((p) => p.id).toList(),
    );
    return _createdGroup!;
  }
}

void main() {
  group('GroupCreateScreen', () {
    testWidgets('displays group name text field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      expect(find.text('Group Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        find.text('Leave empty to auto-generate from members'),
        findsOneWidget,
      );
    });

    testWidgets('displays add people section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      expect(find.text('Add People'), findsOneWidget);
      expect(find.text('Minimum 2 people required'), findsOneWidget);
      expect(find.text('Add Person'), findsOneWidget);
    });

    testWidgets('displays person count badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('can add a person', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      // Click "Add Person" button
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      // Form should appear
      expect(find.text('Person name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Enter name
      final nameField = find.byType(TextFormField).last;
      await tester.enterText(nameField, 'Alice');
      await tester.pumpAndSettle();

      // Click "Add Person" button in form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      // Person should appear in list
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('shows validation error for empty person name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      // Click "Add Person" button
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      // Click "Add Person" without entering name
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      // Error should appear
      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows validation error for name exceeding max length',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      // Click "Add Person" button
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      // Enter name longer than 20 characters
      final nameField = find.byType(TextFormField).last;
      await tester.enterText(nameField, 'This is a very long name that is more than 20 chars');
      await tester.pumpAndSettle();

      // Trigger validation by tapping add button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      // Error should appear
      expect(find.text('Name must be 20 characters or less'), findsOneWidget);
    });

    testWidgets('can remove a person', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      // Add two people
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Alice');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Bob');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      // Remove one person
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('save button is disabled with less than 2 people',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      // Save button should be disabled initially
      final saveButton = find.widgetWithText(ElevatedButton, 'Save');
      expect(saveButton, findsOneWidget);

      // Button should be disabled
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, null);
    });

    testWidgets('save button is enabled with 2 or more people',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      // Add two people
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Alice');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Bob');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      // Save button should be enabled now
      final saveButton = find.widgetWithText(ElevatedButton, 'Save');
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays snackbar on group creation success',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GroupCreateScreen(receipt: mockReceipt),
            ),
          ),
        ),
      );

      // Add two people
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Alice');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Bob');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      // Enter group name
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Group',
      );
      await tester.pumpAndSettle();

      // Click save
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Snackbar should appear
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('minimum 2 people validation shows snackbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GroupCreateScreen(receipt: mockReceipt),
            ),
          ),
        ),
      );

      // Add only one person
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Alice');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Person').last);
      await tester.pumpAndSettle();

      // Try to save (should fail)
      // Save button should still be disabled, so we can't even tap it
      final saveButton = find.widgetWithText(ElevatedButton, 'Save');
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, null);
    });

    testWidgets('displays help text about groups',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      expect(
        find.text(
          'Groups help you quickly split bills between the same people. Each person has an emoji identifier for easy recognition.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('appbar title is Create Group', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsProvider.overrideWith(
              () => MockGroupsNotifier(groups: const [], people: const []),
            ),
          ],
          child: MaterialApp(
            home: GroupCreateScreen(receipt: mockReceipt),
          ),
        ),
      );

      expect(find.text('Create Group'), findsOneWidget);
    });
  });
}
