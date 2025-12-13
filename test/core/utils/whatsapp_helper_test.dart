import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/core/utils/whatsapp_helper.dart';

void main() {
  group('WhatsAppHelper', () {
    group('generateInviteMessage', () {
      test('should generate invite message with all required fields', () {
        // Arrange
        const groupName = 'Test Group';
        const inviteCode = 'ABC123';
        const deepLink = 'quicksplit://invite/ABC123';

        // Act
        final message = WhatsAppHelper.generateInviteMessage(
          groupName: groupName,
          inviteCode: inviteCode,
          deepLink: deepLink,
        );

        // Assert
        expect(message, contains(groupName));
        expect(message, contains(inviteCode));
        expect(message, contains(deepLink));
        expect(message, contains('QuickSplit'));
      });

      test('should generate message with proper structure', () {
        // Arrange
        const groupName = 'Family Budget';
        const inviteCode = 'XYZ789';
        const deepLink = 'quicksplit://invite/XYZ789';

        // Act
        final message = WhatsAppHelper.generateInviteMessage(
          groupName: groupName,
          inviteCode: inviteCode,
          deepLink: deepLink,
        );

        // Assert
        expect(message, isNotEmpty);
        expect(message.split('\n').length, greaterThan(3)); // Multi-line message
      });
    });

    group('Message Validation', () {
      test('should handle special characters in group name', () {
        // Arrange
        const groupName = 'Team "Alpha" & Co.';
        const inviteCode = 'TEST01';
        const deepLink = 'quicksplit://invite/TEST01';

        // Act
        final message = WhatsAppHelper.generateInviteMessage(
          groupName: groupName,
          inviteCode: inviteCode,
          deepLink: deepLink,
        );

        // Assert
        expect(message, contains(groupName));
        expect(message, contains('Team "Alpha" & Co.'));
      });

      test('should handle emoji in group name', () {
        // Arrange
        const groupName = 'Office Lunch 🍱';
        const inviteCode = 'EMOJI1';
        const deepLink = 'quicksplit://invite/EMOJI1';

        // Act
        final message = WhatsAppHelper.generateInviteMessage(
          groupName: groupName,
          inviteCode: inviteCode,
          deepLink: deepLink,
        );

        // Assert
        expect(message, contains('🍱'));
        expect(message, contains('Office Lunch'));
      });
    });

    group('isWhatsAppInstalled', () {
      test('should return a Future<bool>', () {
        // Act
        final result = WhatsAppHelper.isWhatsAppInstalled();

        // Assert
        expect(result, isA<Future<bool>>());
      });
    });
  });
}
