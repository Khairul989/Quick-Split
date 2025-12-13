import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/assign/domain/models/person_share.dart';

/// Helper class for WhatsApp integration
/// Generates and launches WhatsApp messages with invite links
class WhatsAppHelper {
  static final _logger = Logger();

  /// Generate a WhatsApp invite message with deep link
  /// Args:
  ///   - groupName: Name of the group being invited to
  ///   - inviteCode: 6-character invite code
  ///   - deepLink: Generated deep link (e.g., quicksplit://invite/ABC123)
  /// Returns: Formatted message ready for WhatsApp
  static String generateInviteMessage({
    required String groupName,
    required String inviteCode,
    required String deepLink,
  }) {
    return '''Hey! I've added you to "$groupName" on QuickSplit.

Join the group using this link:
$deepLink

Or enter code: $inviteCode

QuickSplit makes splitting bills super easy!''';
  }

  /// Share an invite via WhatsApp
  /// Opens WhatsApp with a pre-filled message
  /// Args:
  ///   - message: The message to send
  ///   - phoneNumber: Optional phone number (if not provided, WhatsApp contact picker opens)
  /// Throws: Exception if WhatsApp is not installed
  static Future<void> shareViaWhatsApp({
    required String message,
    String? phoneNumber,
  }) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);
      final waUrl = phoneNumber != null && phoneNumber.isNotEmpty
          ? 'https://wa.me/$phoneNumber?text=$encodedMessage'
          : 'https://wa.me/?text=$encodedMessage';

      final uri = Uri.parse(waUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _logger.d('Opened WhatsApp with message');
      } else {
        _logger.w('WhatsApp not installed or cannot be launched');
        throw Exception('WhatsApp is not installed on this device');
      }
    } catch (e) {
      _logger.e('Error sharing via WhatsApp: $e');
      rethrow;
    }
  }

  /// Check if WhatsApp is installed
  /// Returns true if WhatsApp can be launched
  static Future<bool> isWhatsAppInstalled() async {
    try {
      final uri = Uri.parse('https://wa.me/');
      return await canLaunchUrl(uri);
    } catch (e) {
      _logger.e('Error checking WhatsApp installation: $e');
      return false;
    }
  }

  /// Share invite via WhatsApp with phone number
  /// Args:
  ///   - phoneNumber: Phone number in international format (e.g., +1234567890)
  ///   - groupName: Name of the group
  ///   - inviteCode: 6-character invite code
  ///   - deepLink: Generated deep link
  static Future<void> shareInviteWithPhone({
    required String phoneNumber,
    required String groupName,
    required String inviteCode,
    required String deepLink,
  }) async {
    try {
      final message = generateInviteMessage(
        groupName: groupName,
        inviteCode: inviteCode,
        deepLink: deepLink,
      );

      await shareViaWhatsApp(message: message, phoneNumber: phoneNumber);

      _logger.d('Shared invite via WhatsApp to $phoneNumber');
    } catch (e) {
      _logger.e('Error sharing invite with phone: $e');
      rethrow;
    }
  }

  /// Share invite via WhatsApp contact picker
  /// Opens WhatsApp and lets user select contact
  /// Args:
  ///   - groupName: Name of the group
  ///   - inviteCode: 6-character invite code
  ///   - deepLink: Generated deep link
  static Future<void> shareInviteToContact({
    required String groupName,
    required String inviteCode,
    required String deepLink,
  }) async {
    try {
      final message = generateInviteMessage(
        groupName: groupName,
        inviteCode: inviteCode,
        deepLink: deepLink,
      );

      await shareViaWhatsApp(message: message);
      _logger.d('Opened WhatsApp contact picker for invite');
    } catch (e) {
      _logger.e('Error opening WhatsApp contact picker: $e');
      rethrow;
    }
  }

  /// Share a bill summary via WhatsApp
  /// Shows individual breakdown for a specific person
  /// Args:
  ///   - receipt: The receipt being shared
  ///   - userShare: The PersonShare for the recipient
  ///   - phoneNumber: Optional phone number (if not provided, WhatsApp contact picker opens)
  static Future<void> shareBillSummary({
    required Receipt receipt,
    required PersonShare userShare,
    String? phoneNumber,
  }) async {
    try {
      final message = _generateBillSummaryMessage(receipt: receipt, userShare: userShare);
      await shareViaWhatsApp(message: message, phoneNumber: phoneNumber);
      _logger.d('Shared bill summary via WhatsApp');
    } catch (e) {
      _logger.e('Error sharing bill summary: $e');
      rethrow;
    }
  }

  /// Generate bill summary message
  static String _generateBillSummaryMessage({
    required Receipt receipt,
    required PersonShare userShare,
  }) {
    return '''Hi ${userShare.personName}! 👋

Here's your share from ${receipt.merchantName}:

Items Subtotal: RM ${userShare.itemsSubtotal.toStringAsFixed(2)}
SST: RM ${userShare.sst.toStringAsFixed(2)}
Service Charge: RM ${userShare.serviceCharge.toStringAsFixed(2)}
Rounding: RM ${userShare.rounding.toStringAsFixed(2)}

💰 Your Total: RM ${userShare.total.toStringAsFixed(2)}

Split via QuickSplit''';
  }

  /// Send a payment reminder via WhatsApp
  /// Args:
  ///   - phoneNumber: Phone number of the person
  ///   - personName: Name of the person
  ///   - amount: Amount owed
  ///   - merchantName: Merchant name from receipt
  static Future<void> sendPaymentReminder({
    required String phoneNumber,
    required String personName,
    required double amount,
    required String merchantName,
  }) async {
    try {
      final message = _generatePaymentReminderMessage(
        personName: personName,
        amount: amount,
        merchantName: merchantName,
      );
      await shareViaWhatsApp(message: message, phoneNumber: phoneNumber);
      _logger.d('Sent payment reminder via WhatsApp to $phoneNumber');
    } catch (e) {
      _logger.e('Error sending payment reminder: $e');
      rethrow;
    }
  }

  /// Generate payment reminder message
  static String _generatePaymentReminderMessage({
    required String personName,
    required double amount,
    required String merchantName,
  }) {
    return '''Hey $personName! 👋

Friendly reminder about your share from $merchantName:

💰 Amount: RM ${amount.toStringAsFixed(2)}

Please settle when you get a chance. Thanks! 🙏''';
  }
}
