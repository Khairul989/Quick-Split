// Utilities for phone number handling and validation
// Phone numbers are stored in E.164 format: +{country_code}{number}
// Example: +60123456789 (Malaysia)

/// Normalize phone number input to E.164 format
/// Accepts various formats and converts to international E.164 format
/// Defaults to Malaysia (+60) if no country code provided
String normalizePhoneNumber(String input, {String defaultCountryCode = '+60'}) {
  if (input.isEmpty) {
    return '';
  }

  // Remove all non-digit characters except leading +
  String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

  // If it starts with +, it's already in international format
  if (cleaned.startsWith('+')) {
    return cleaned;
  }

  // If it starts with 0 (local Malaysia format), replace with country code
  if (cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
  }

  // If no leading digits suggest country code, add default
  if (!cleaned.startsWith(defaultCountryCode.replaceAll('+', ''))) {
    cleaned = defaultCountryCode.replaceAll('+', '') + cleaned;
  }

  // Ensure it starts with +
  if (!cleaned.startsWith('+')) {
    cleaned = '+$cleaned';
  }

  return cleaned;
}

/// Validate phone number is in proper E.164 format
/// E.164 format: +{1-3 digits country code}{1-14 digits number}
bool isValidPhoneNumber(String phone) {
  if (phone.isEmpty) {
    return false;
  }

  // E.164 format regex: + followed by 1-3 country code digits, then 1-14 number digits
  final e164Regex = RegExp(r'^\+\d{1,3}\d{1,14}$');

  return e164Regex.hasMatch(phone);
}

/// Format E.164 phone number for display
/// Example: +60123456789 -> +60 123-456 789
String formatPhoneForDisplay(String e164Phone) {
  if (!isValidPhoneNumber(e164Phone)) {
    return e164Phone;
  }

  // Extract country code (+ followed by 1-3 digits)
  final countryCodeMatch = RegExp(r'^\+(\d{1,3})(.+)$').firstMatch(e164Phone);

  if (countryCodeMatch == null) {
    return e164Phone;
  }

  final countryCode = countryCodeMatch.group(1)!;
  final number = countryCodeMatch.group(2)!;

  // Format the number part based on length (insert hyphens for readability)
  // Example: 123456789 -> 123-456 789
  if (number.length >= 6) {
    final first = number.substring(0, 3);
    final second = number.substring(3, 6);
    final rest = number.substring(6);
    return '+$countryCode $first-$second $rest';
  }

  return e164Phone;
}

/// Extract country code from E.164 formatted phone number
/// Example: +60123456789 -> +60
String getCountryCode(String e164Phone) {
  if (!isValidPhoneNumber(e164Phone)) {
    return '';
  }

  final match = RegExp(r'^\+(\d{1,3})').firstMatch(e164Phone);
  return match != null ? '+${match.group(1)}' : '';
}
