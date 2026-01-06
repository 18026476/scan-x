import 'dart:convert';

bool _looksBroken(String s) {
  return s.contains('Ã') || s.contains('Â') || s.contains('â€') || s.contains('�');
}

String repairMojibake(String input) {
  if (input.isEmpty) return input;
  if (!_looksBroken(input)) return input;

  String s = input;

  // Try 2 rounds latin1 -> utf8 repair (handles double-mojibake)
  for (int i = 0; i < 2; i++) {
    try {
      final bytes = latin1.encode(s);
      final repaired = utf8.decode(bytes, allowMalformed: true);
      if (repaired == s) break;
      s = repaired;
      if (!_looksBroken(s)) break;
    } catch (_) {
      break;
    }
  }

  // Still broken? Strip non-ASCII to keep UI readable
  if (_looksBroken(s)) {
    s = s.replaceAll(RegExp(r'[^\x20-\x7E]+'), ' ');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  return s;
}

String sanitizeUiText(String s) => repairMojibake(s);