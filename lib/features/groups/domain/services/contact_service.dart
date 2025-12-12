import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/person.dart';

/// Exception thrown when contact permission is denied
class ContactPermissionDeniedException implements Exception {
  final String message;

  ContactPermissionDeniedException(this.message);

  @override
  String toString() => message;
}

/// Service for managing contact access and conversion
class ContactService {
  static const List<String> _defaultEmojis = [
    '👨', '👩', '👦', '👧', '👴', '👵',
    '🧑', '👨‍🦱', '👩‍🦱', '👨‍🦲', '👩‍🦲',
    '😊', '😄', '😎', '🤓', '😌', '🥰'
  ];

  /// Check if app has permission to read contacts
  static Future<bool> hasPermission() async {
    try {
      final status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request permission to read contacts
  static Future<bool> requestPermission() async {
    try {
      final status = await Permission.contacts.request();
      return status.isGranted;
    } catch (e) {
      throw ContactPermissionDeniedException('Failed to request contact permission: $e');
    }
  }

  /// Fetch all contacts from device
  static Future<List<Contact>> fetchContacts() async {
    try {
      final hasPerms = await hasPermission();
      if (!hasPerms) {
        throw ContactPermissionDeniedException('Contact permission not granted');
      }

      final contacts = await FlutterContacts.getContacts();
      return contacts;
    } catch (e) {
      rethrow;
    }
  }

  /// Convert Contact to Person model
  static Person contactToPerson(Contact contact) {
    // Get name - fallback to phone number if name is empty
    String name = contact.displayName;
    if (name.trim().isEmpty && contact.phones.isNotEmpty) {
      name = contact.phones.first.number;
    }
    if (name.trim().isEmpty) {
      name = 'Unknown Contact';
    }

    // Truncate name to max 20 chars for display consistency
    if (name.length > 20) {
      name = name.substring(0, 20).trim();
    }

    // Get first phone number
    String? phoneNumber;
    if (contact.phones.isNotEmpty) {
      phoneNumber = contact.phones.first.number;
    }

    // Get first email
    String? email;
    if (contact.emails.isNotEmpty) {
      email = contact.emails.first.address;
    }

    // Generate consistent emoji for contact
    final emoji = _generateEmojiForContact(contact.id);

    return Person(
      name: name,
      emoji: emoji,
      phoneNumber: phoneNumber,
      email: email,
      contactId: contact.id,
    );
  }

  /// Generate a deterministic emoji for a contact based on their ID
  static String _generateEmojiForContact(String identifier) {
    if (identifier.isEmpty) {
      return _defaultEmojis[0];
    }

    // Use hash of identifier to consistently pick the same emoji
    final hashCode = identifier.hashCode.abs();
    final index = hashCode % _defaultEmojis.length;
    return _defaultEmojis[index];
  }
}
