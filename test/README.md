# QuickSplit Test Suite

**Last Updated:** December 13, 2025

## Overview

This directory contains unit tests, widget tests, and integration tests for the QuickSplit application.

## Test Coverage

### Unit Tests

**Phase 5: Contact Matching**
- `test/features/groups/services/contact_matching_service_test.dart`
  - Cache validation tests
  - Firestore query tests
  - Empty match handling
  - Cache expiration logic

**Phase 8: WhatsApp Integration**
- `test/core/utils/whatsapp_helper_test.dart`
  - Invite message generation
  - Bill summary message generation
  - Payment reminder message generation
  - WhatsApp availability check

**Phase 1: Firebase Sync**
- `test/features/groups/repositories/firebase_group_repository_test.dart`
  - Group creation tests
  - Member management tests
  - Group deletion tests
  - Error handling tests

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/features/groups/services/contact_matching_service_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Tests in Watch Mode
```bash
flutter test --watch
```

## Test Setup

### Prerequisites

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate Mock Files** (if using mockito)
   ```bash
   flutter pub run build_runner build
   ```

### Mocking Dependencies

Tests use `mockito` for mocking:
- `@GenerateMocks([ClassName])` annotation
- Run `build_runner` to generate `.mocks.dart` files
- Import generated mocks: `import 'file_name_test.mocks.dart';`

## Test Structure

### AAA Pattern (Arrange-Act-Assert)

```dart
test('should do something', () {
  // Arrange: Set up test data and mocks
  final service = MyService();
  when(mockDependency.doSomething()).thenReturn(expectedValue);

  // Act: Execute the function being tested
  final result = service.performAction();

  // Assert: Verify the result
  expect(result, equals(expectedValue));
  verify(mockDependency.doSomething()).called(1);
});
```

## Test Types

### Unit Tests
- Test individual functions/classes in isolation
- Mock all external dependencies
- Focus on business logic
- Located: `test/*/`

### Widget Tests
- Test UI components
- Verify rendering and user interactions
- Use `testWidgets()` function
- Located: `test/widgets/`

### Integration Tests
- Test complete user flows
- May use real Firebase emulators
- Located: `integration_test/`

## Coverage Goals

- **Business Logic:** > 80%
- **Services/Repositories:** > 70%
- **Utilities:** > 90%
- **Overall:** > 70%

## Continuous Integration

Tests run automatically on:
- Every commit (pre-commit hook)
- Pull request creation
- Merge to main branch

## Troubleshooting

### Build Runner Issues
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Mock Issues
Use `fake_cloud_firestore` for Firestore tests:
```bash
flutter pub add dev:fake_cloud_firestore
```

### Test Timeout
Increase timeout for slow tests:
```dart
test('slow test', () async {
  // ...
}, timeout: Timeout(Duration(seconds: 30)));
```

## Next Steps

### Tests to Add

1. **Widget Tests:**
   - `summary_screen_test.dart` - WhatsApp share button
   - `history_detail_screen_test.dart` - Payment reminder button
   - `find_friends_screen_test.dart` - Contact matching UI

2. **Integration Tests:**
   - Complete invite flow (create → share → accept)
   - Contact matching end-to-end
   - Notification receiving and routing

3. **Cloud Functions Tests:**
   - `functions/src/__tests__/notifications.test.ts`
   - Test Firestore triggers
   - Test FCM sending logic

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Firebase Testing Guide](https://firebase.google.com/docs/emulator-suite)
