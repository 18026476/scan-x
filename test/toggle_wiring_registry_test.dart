import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_app/core/services/toggle_wiring_registry.dart';

void main() {
  test('No dead toggles: every toggle has a consumer', () {
    final dead = ToggleWiringRegistry.toggles
        .where((t) => t.consumer == ToggleConsumer.none)
        .toList();

    final msg = 'Dead toggles found: ' + dead.map((e) => e.key).join(', ');
    expect(dead, isEmpty, reason: msg);
  });

  test('No duplicate toggle keys', () {
    final keys = ToggleWiringRegistry.toggles.map((t) => t.key).toList();
    expect(
      keys.toSet().length,
      keys.length,
      reason: 'Duplicate toggle keys found in registry.',
    );
  });
}
