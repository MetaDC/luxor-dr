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
