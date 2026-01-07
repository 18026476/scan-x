import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_app/core/services/toggle_wiring_registry.dart';

void main() {
  test('No dead toggles: every registry key is referenced somewhere in lib/', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory not found.');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    expect(dartFiles, isNotEmpty, reason: 'No Dart files found under lib/.');

    final allText = StringBuffer();
    for (final f in dartFiles) {
      try {
        allText.writeln(f.readAsStringSync());
      } catch (_) {}
    }
    final haystack = allText.toString();

    final missing = <String>[];
    for (final t in ToggleWiringRegistry.toggles) {
      final key = t.key;
      final referenced = haystack.contains(key) ||
          haystack.contains("''") ||
          haystack.contains('""');
      if (!referenced) missing.add(key);
    }

    expect(
      missing,
      isEmpty,
      reason: 'Dead toggle(s) found (never referenced in lib/): ',
    );
  });
}