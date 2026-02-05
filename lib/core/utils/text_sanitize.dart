import 'dart:convert';

/// SCAN-X text sanitizer (UI-safe, permanent)
///
/// Fixes classic mojibake like:
///   Ãƒâ€¦ / Ã‚ / Ã¢â‚¬Â¦ / â€šÃ„ / ï¿½
///
/// Strategy:
/// 1) Remove obvious broken markers (U+FFFD, stray Ã‚)
/// 2) If string looks like UTF-8 bytes decoded as Latin-1, repair via:
///    utf8.decode(latin1.encode(s), allowMalformed: true)
///    (run twice to handle double-encoding)
/// 3) Normalize punctuation (quotes/dashes/arrows/bullets)
/// 4) Never throw.
String scanxTextSafe(String? input) {
  var s = (input ?? '').toString();
  if (s.isEmpty) return s;

  s = s
      .replaceAll('\uFFFD', '')
      .replaceAll('\u00C2', '') // Ã‚
      .replaceAll('Ã‚', '');

  bool looksBroken(String x) =>
      x.contains('\u00C3') || // Ãƒ
      x.contains('\u00C2') || // Ã‚
      x.contains('\u00E2') || // Ã¢
      x.contains('\u201A') || // â€š
      x.contains('\uFFFD');

  int score(String x) {
    int countOf(String sub) {
      var c = 0;
      var i = 0;
      while (true) {
        final p = x.indexOf(sub, i);
        if (p < 0) break;
        c++;
        i = p + sub.length;
      }
      return c;
    }
    return countOf('\u00C3') +
        countOf('\u00C2') +
        countOf('\u00E2') +
        countOf('\u201A') +
        countOf('\uFFFD');
  }

  for (var i = 0; i < 2; i++) {
    if (!looksBroken(s)) break;
    try {
      final repaired = utf8.decode(latin1.encode(s), allowMalformed: true);
      if (repaired.isNotEmpty && score(repaired) <= score(s)) s = repaired;
    } catch (_) {}
  }

  s = s
      .replaceAll('\u2022', '- ') // -
      .replaceAll('\u2192', '->') // ->
      .replaceAll('\u2014', '-')  // â€”
      .replaceAll('\u2013', '-')  // â€“
      .replaceAll('\u2019', "'")  // â€™
      .replaceAll('\u201C', '"')  // â€œ
      .replaceAll('\u201D', '"'); // â€

  s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return s.trim();
}
