import 'text_sanitize.dart';

/// Backward-compatible helpers.
bool scanxLooksBroken(String s) {
  return s.contains('\u00C3') ||
      s.contains('\u00C2') ||
      s.contains('\u00E2') ||
      s.contains('\u201A') ||
      s.contains('\uFFFD');
}

/// Single source of truth.
String scanxCleanText(String s) => scanxTextSafe(s);

/// Global alias used by some UI/PDF widgets.
/// Keep it global so you do NOT need widget-level helper methods.
String sanitizeUiText(String s) => scanxTextSafe(s);