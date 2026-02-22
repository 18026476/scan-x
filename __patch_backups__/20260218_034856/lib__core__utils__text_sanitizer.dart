// lib/core/utils/text_sanitizer.dart
// Keep import-free. No directives. Only declarations.

class TextSanitizer {
  /// Converts Nmap-style uncertain service guesses:
  ///   "microsoft-ds?" -> "microsoft-ds (Uncertain)"
  /// Only applies to a trailing '?' (common Nmap uncertainty marker).
  static String normalizeServiceGuess(String input) {
    final t = input.trim();
    if (t.endsWith('?')) {
      final base = t.substring(0, t.length - 1).trim();
      if (base.isEmpty) return 'Uncertain';
      return '\ (Uncertain)';
    }
    if (t == '?' || t.isEmpty) return 'Uncertain';
    return t;
  }

  /// Cleans common mojibake/encoding garbage from tool output for UI display.
  static String normalizeUi(String input) {
    var s = input;

    // Hard-remove the exact bullet token you keep seeing.
    s = s.replaceAll('\u2022', '');

    // Common mojibake / CP1252/UTF8-crossdecode fragments
    const repl = <String, String>{
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
    s = s.replaceAll(RegExp(r'â[^\s]{0,8}'), '');

    // Collapse whitespace + trim
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }
}
