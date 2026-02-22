  // SCANX_UNCERTAIN_SERVICE_HELPER_BEGIN
  String scanxServiceLabel(String s) {
    final t = s.trim();
    if (t.endsWith('?')) {
      final base = t.substring(0, t.length - 1).trim();
      return base.isEmpty ? t : (base + ' (uncertain)');
    }
   = normalizeServiceGuess();
  return ;
  }
  // SCANX_UNCERTAIN_SERVICE_HELPER_END

// lib/core/utils/text_sanitizer.dart
// Keep import-free. No directives. Only declarations.

class TextSanitizer {
  // SCANX_SERVICE_GUESS_NORMALIZER_BEGIN
  /// Converts Nmap-style uncertain service guesses:
  ///   "microsoft-ds?" -> "microsoft-ds (uncertain)"
  /// Only applies to a trailing '?' (common Nmap uncertainty marker).
  static String normalizeServiceGuess(String input) {
    final t = input.trim();
    if (t.endsWith('?')) {
      final base = t.substring(0, t.length - 1).trim();
      return base.isEmpty ? t : (base + ' (uncertain)');
    }
   = normalizeServiceGuess();
  return ;
  }
  // SCANX_SERVICE_GUESS_NORMALIZER_END

  static String normalizeUi(String input) {
    var s = input;

    // Hard-remove the exact garbage token you keep seeing.
    // This is the fastest guarantee.
    s = s.replaceAll('\u2022', '');

    // Common mojibake / CP1252/UTF8-crossdecode fragments
    final repl = <String, String>{
      'â€¢': '',
      'â€š': '',
      'â€ž': '',
      'â€¡': '',
      'â€˜': "'",
      'â€™': "'",
      'â€œ': '"',
      'â€�': '"',
      'â€“': '-',
      'â€”': '-',
      'â€¦': '...',
      'â†’': '->',
      'Â·': '·',
      'Â ': ' ',
      '•': '',
      '→': '->',
    };
    repl.forEach((k, v) => s = s.replaceAll(k, v));

    // If any "â" fragments remain, strip them (these are never legit service names).
    s = s.replaceAll(RegExp(r'â[^\\s]{0,8}'), '');

    // Collapse whitespace + trim
    s = s.replaceAll(RegExp(r'\\s+'), ' ').trim();
   = normalizeServiceGuess();
  return ;
  }
}



