String cleanPhoneNumber(String phone) {
  var cleaned = phone.trim();
  if (cleaned.isEmpty) return '';

  // Remove spaces, dashes, brackets, etc.
  cleaned = cleaned.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  // If already has +, keep it (international number)
  if (cleaned.startsWith('+')) {
    // nothing to do
  }
  // If starts with 91 and has no +
  else if (cleaned.startsWith('91') && cleaned.length > 10) {
    cleaned = '+$cleaned';
  }
  // Otherwise assume Indian local number
  else {
    cleaned = '+91$cleaned';
  }
  return cleaned;
}

bool isValidEmail(String email) {
  final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );
  return emailRegex.hasMatch(email);
}

bool isValidIndianPhoneNumber(String phone) {
  final RegExp phoneRegex = RegExp(
    r"^(\+91[\s]?)?[6-9][0-9]{9}$",
  ); // Allows optional +91 and ensures 10-digit format
  return phoneRegex.hasMatch(phone);
}

// Validates international phone numbers per E.164 (7–15 digits, optional + prefix).
// Strips spaces, hyphens, and parentheses before checking.
bool isValidInternationalPhone(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-().]+'), '');
  return RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(cleaned);
}

bool isValidPhoneNumber(String phone) {
  var cleaned = phone.replaceAll(RegExp(r'[\s\-().]+'), '');
  if (cleaned.isEmpty) return false;
  if (!cleaned.startsWith('+')) {
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = '+$cleaned';
    } else {
      cleaned = '+91$cleaned';
    }
  }
  if (cleaned.startsWith('+91')) {
    final numOnly = cleaned.substring(3);
    return RegExp(r'^[6-9]\d{9}$').hasMatch(numOnly);
  }
  return RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(cleaned);
}
