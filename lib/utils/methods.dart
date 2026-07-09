List<String> generateSearchCombinations(String text) {
  final Set<String> keywords = {};

  final cleaned = text.trim().toLowerCase();

  final words = cleaned.split(RegExp(r'\s+'));

  // Prefixes of each word
  for (final word in words) {
    for (int i = 3; i <= word.length; i++) {
      keywords.add(word.substring(0, i));
    }
  }

  // Prefixes of the complete string
  for (int i = 3; i <= cleaned.length; i++) {
    keywords.add(cleaned.substring(0, i));
  }

  return keywords.toList();
}

(String, String) splitStoredPhone(String phone) {
  final trimmed = phone.trim();
  if (trimmed.contains(' ')) {
    final idx = trimmed.indexOf(' ');
    final code = trimmed.substring(0, idx).trim();
    final number = trimmed.substring(idx + 1).trim();
    if (code.startsWith('+')) {
      return (code, number);
    }
  }

  // Fallback if no space:
  if (trimmed.startsWith('+')) {
    if (trimmed.startsWith('+91') && trimmed.length >= 13) {
      return ('+91', trimmed.substring(3));
    }
    if (trimmed.startsWith('+1') && trimmed.length >= 12) {
      return ('+1', trimmed.substring(2));
    }
    if (trimmed.length > 10) {
      final codeLen = trimmed.length - 10;
      return (trimmed.substring(0, codeLen), trimmed.substring(codeLen));
    }
  }
  return ('+91', trimmed);
}
